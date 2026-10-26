import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: '15mb' }));

const apiKey = process.env.GEMINI_API_KEY;
const DATABASE_URL = process.env.DATABASE_URL;
const NYLAS_API_KEY = process.env.NYLAS_API_KEY;
const NYLAS_DOMAIN = 'sahhaha-app.nylas.email';
const NYLAS_SENDER_EMAIL =
  process.env.NYLAS_SENDER_EMAIL || 'no-reply@sahhaha-app.nylas.email';
const AUTH_SECRET = process.env.AUTH_SECRET;

if (!apiKey) console.error('GEMINI_API_KEY غير موجود');
if (!DATABASE_URL) console.error('DATABASE_URL غير موجود');
if (!NYLAS_API_KEY) console.error('NYLAS_API_KEY غير موجود');
if (!AUTH_SECRET) console.error('AUTH_SECRET غير موجود');

let sqlPromise;

async function getSql() {
  if (!DATABASE_URL) {
    throw new Error('DATABASE_URL غير موجود في Vercel Environment Variables');
  }

  if (!sqlPromise) {
    sqlPromise = import('@neondatabase/serverless')
      .then(({ neon }) => neon(DATABASE_URL));
  }

  return sqlPromise;
}

async function ensureTables(sql) {
  await sql`
    CREATE TABLE IF NOT EXISTS students (
      id BIGSERIAL PRIMARY KEY,
      full_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      password_salt TEXT NOT NULL,
      stage TEXT NOT NULL,
      grade TEXT NOT NULL,
      reset_code_hash TEXT,
      reset_expires_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
}

function hashPassword(
  password,
  salt = crypto.randomBytes(16).toString('hex')
) {
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return { hash, salt };
}

function verifyPassword(password, hash, salt) {
  const derived = crypto.scryptSync(password, salt, 64);
  const stored = Buffer.from(hash, 'hex');

  return (
    stored.length === derived.length &&
    crypto.timingSafeEqual(stored, derived)
  );
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function createResetCode() {
  return String(crypto.randomInt(100000, 1000000));
}

function base64Url(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function createAuthToken(userId) {
  if (!AUTH_SECRET) {
    throw new Error('AUTH_SECRET غير موجود');
  }

  const header = base64Url(
    JSON.stringify({
      alg: 'HS256',
      typ: 'JWT',
    })
  );

  const payload = base64Url(
    JSON.stringify({
      sub: String(userId),
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60,
    })
  );

  const unsigned = `${header}.${payload}`;

  const signature = crypto
    .createHmac('sha256', AUTH_SECRET)
    .update(unsigned)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${unsigned}.${signature}`;
}

function json(res, status, body) {
  return res.status(status).json(body);
}

function verifyAuthToken(token) {
  if (!token || !AUTH_SECRET) return null;

  try {
    const parts = String(token).split('.');

    if (parts.length !== 3) return null;

    const [header, payload, signature] = parts;
    const unsigned = `${header}.${payload}`;

    const expected = crypto
      .createHmac('sha256', AUTH_SECRET)
      .update(unsigned)
      .digest('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    const actualBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expected);

    if (
      actualBuffer.length !== expectedBuffer.length ||
      !crypto.timingSafeEqual(actualBuffer, expectedBuffer)
    ) {
      return null;
    }

    const decodeBase64Url = (value) => {
      const padded = String(value)
        .replace(/-/g, '+')
        .replace(/_/g, '/')
        .padEnd(
          Math.ceil(String(value).length / 4) * 4,
          '='
        );

      return JSON.parse(
        Buffer.from(padded, 'base64').toString('utf8')
      );
    };

    const data = decodeBase64Url(payload);

    if (
      !data?.sub ||
      !data?.exp ||
      Number(data.exp) <= Math.floor(Date.now() / 1000)
    ) {
      return null;
    }

    return {
      userId: String(data.sub),
    };
  } catch (_) {
    return null;
  }
}

function getAuthToken(req) {
  const header = req.headers?.authorization || '';

  if (!header.toLowerCase().startsWith('bearer ')) {
    return null;
  }

  return header.slice(7).trim();
}

async function sendResetEmail(email, code) {
  if (!NYLAS_API_KEY) {
    throw new Error(
      'NYLAS_API_KEY غير موجود في Vercel Environment Variables'
    );
  }

  const response = await fetch(
    `https://api.us.nylas.com/v3/domains/${NYLAS_DOMAIN}/messages/send`,
    {
      method: 'POST',

      headers: {
        Authorization: `Bearer ${NYLAS_API_KEY}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },

      body: JSON.stringify({
        from: {
          name: 'المصحح الذكي',
          email: NYLAS_SENDER_EMAIL,
        },

        to: [
          {
            email,
          },
        ],

        subject: 'رمز إعادة تعيين الحساب',

        body: `
          <div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8">
            <h2>إعادة تعيين رمز الحساب</h2>

            <p>
              رمز إعادة التعيين الخاص بحسابك في
              <b>المصحح الذكي</b>
              هو:
            </p>

            <div
              style="
                font-size:32px;
                font-weight:bold;
                letter-spacing:8px;
                margin:20px 0
              "
            >
              ${code}
            </div>

            <p>الرمز صالح لمدة 10 دقائق فقط.</p>

            <p>
              إذا لم تطلب إعادة التعيين،
              يمكنك تجاهل هذه الرسالة.
            </p>
          </div>
        `,
      }),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `فشل إرسال الإيميل عبر Nylas: ${text}`
    );
  }
}

function validateRegisterInput({
  fullName,
  email,
  password,
  stage,
  grade,
}) {
  if (!fullName || !email || !password || !stage || !grade) {
    return 'جميع الحقول مطلوبة';
  }

  if (String(fullName).trim().split(/\s+/).length < 3) {
    return 'اكتب الاسم الثلاثي';
  }

  if (!String(email).includes('@')) {
    return 'اكتب إيميل صحيح';
  }

  if (String(password).length < 6) {
    return 'الرمز يجب أن يكون 6 أحرف أو أرقام على الأقل';
  }

  if (!['primary', 'middle'].includes(stage)) {
    return 'المرحلة الدراسية غير صحيحة';
  }

  return null;
}

// الصفحة الرئيسية
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'سيرفر مساعد الطالب العراقي يعمل بنجاح 🎉',
  });
});

// ===================== الحسابات =====================

app.post('/api/auth/register', async (req, res) => {
  try {
    const {
      fullName,
      email,
      password,
      stage,
      grade,
    } = req.body || {};

    const validationError = validateRegisterInput({
      fullName,
      email,
      password,
      stage,
      grade,
    });

    if (validationError) {
      return json(res, 400, {
        success: false,
        error: validationError,
      });
    }

    const sql = await getSql();

    await ensureTables(sql);

    const normalizedEmail = String(email)
      .trim()
      .toLowerCase();

    const existing = await sql`
      SELECT id
      FROM students
      WHERE email = ${normalizedEmail}
      LIMIT 1
    `;

    if (existing.length) {
      return json(res, 409, {
        success: false,
        error: 'هذا الإيميل مسجل مسبقًا',
      });
    }

    const {
      hash,
      salt,
    } = hashPassword(String(password));

    const rows = await sql`
      INSERT INTO students
        (
          full_name,
          email,
          password_hash,
          password_salt,
          stage,
          grade
        )
      VALUES
        (
          ${String(fullName).trim()},
          ${normalizedEmail},
          ${hash},
          ${salt},
          ${stage},
          ${grade}
        )
      RETURNING id, full_name, email, stage, grade
    `;

    const user = rows[0];

    return json(res, 201, {
      success: true,

      token: createAuthToken(user.id),

      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        stage: user.stage,
        grade: user.grade,
      },
    });
  } catch (error) {
    console.error('Register Error:', error);

    return json(res, 500, {
      success: false,
      error:
        error.message ||
        'حدث خطأ أثناء إنشاء الحساب',
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const {
      email,
      password,
    } = req.body || {};

    const normalizedEmail = String(email || '')
      .trim()
      .toLowerCase();

    if (!normalizedEmail || !password) {
      return json(res, 400, {
        success: false,
        error: 'الإيميل والرمز مطلوبان',
      });
    }

    const sql = await getSql();

    await ensureTables(sql);

    const rows = await sql`
      SELECT
        id,
        full_name,
        email,
        password_hash,
        password_salt,
        stage,
        grade
      FROM students
      WHERE email = ${normalizedEmail}
      LIMIT 1
    `;

    if (
      !rows.length ||
      !verifyPassword(
        String(password),
        rows[0].password_hash,
        rows[0].password_salt
      )
    ) {
      return json(res, 401, {
        success: false,
        error: 'الإيميل أو الرمز غير صحيح',
      });
    }

    const user = rows[0];

    return json(res, 200, {
      success: true,

      token: createAuthToken(user.id),

      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        stage: user.stage,
        grade: user.grade,
      },
    });
  } catch (error) {
    console.error('Login Error:', error);

    return json(res, 500, {
      success: false,
      error:
        error.message ||
        'حدث خطأ أثناء تسجيل الدخول',
    });
  }
});

// ===================== تحديث بيانات الحساب =====================

app.post('/api/auth/update-profile', async (req, res) => {
  try {
    const auth = verifyAuthToken(
      getAuthToken(req)
    );

    if (!auth) {
      return json(res, 401, {
        success: false,
        error:
          'جلسة الدخول غير صالحة أو منتهية، سجل الدخول مرة ثانية',
      });
    }

    const {
      fullName,
      email,
      currentPassword,
      newPassword,
    } = req.body || {};

    if (!currentPassword) {
      return json(res, 400, {
        success: false,
        error: 'أدخل الرمز الحالي للتأكيد',
      });
    }

    const sql = await getSql();

    await ensureTables(sql);

    const rows = await sql`
      SELECT
        id,
        full_name,
        email,
        password_hash,
        password_salt,
        stage,
        grade
      FROM students
      WHERE id = ${auth.userId}
      LIMIT 1
    `;

    if (!rows.length) {
      return json(res, 404, {
        success: false,
        error: 'الحساب غير موجود',
      });
    }

    const user = rows[0];

    if (
      !verifyPassword(
        String(currentPassword),
        user.password_hash,
        user.password_salt
      )
    ) {
      return json(res, 401, {
        success: false,
        error: 'الرمز الحالي غير صحيح',
      });
    }

    const nextName = String(
      fullName ?? user.full_name
    ).trim();

    const nextEmail = String(
      email ?? user.email
    )
      .trim()
      .toLowerCase();

    const nextPassword =
      newPassword == null
        ? ''
        : String(newPassword);

    if (
      nextName
        .split(/\s+/)
        .filter(Boolean)
        .length < 3
    ) {
      return json(res, 400, {
        success: false,
        error: 'اكتب الاسم الثلاثي',
      });
    }

    if (!nextEmail.includes('@')) {
      return json(res, 400, {
        success: false,
        error: 'اكتب إيميل صحيح',
      });
    }

    if (
      newPassword != null &&
      nextPassword.length > 0 &&
      nextPassword.length < 6
    ) {
      return json(res, 400, {
        success: false,
        error:
          'الرمز الجديد يجب أن يكون 6 أحرف أو أرقام على الأقل',
      });
    }

    if (nextEmail !== user.email) {
      const existing = await sql`
        SELECT id
        FROM students
        WHERE email = ${nextEmail}
          AND id <> ${auth.userId}
        LIMIT 1
      `;

      if (existing.length) {
        return json(res, 409, {
          success: false,
          error:
            'هذا الإيميل مستخدم من حساب آخر',
        });
      }
    }

    if (
      newPassword != null &&
      nextPassword.length > 0
    ) {
      const {
        hash,
        salt,
      } = hashPassword(nextPassword);

      const updated = await sql`
        UPDATE students
        SET
          full_name = ${nextName},
          email = ${nextEmail},
          password_hash = ${hash},
          password_salt = ${salt}
        WHERE id = ${auth.userId}
        RETURNING id, full_name, email, stage, grade
      `;

      const updatedUser = updated[0];

      return json(res, 200, {
        success: true,

        message:
          'تم تحديث بيانات الحساب والرمز بنجاح',

        token: createAuthToken(
          updatedUser.id
        ),

        user: {
          id: updatedUser.id,
          fullName: updatedUser.full_name,
          email: updatedUser.email,
          stage: updatedUser.stage,
          grade: updatedUser.grade,
        },
      });
    }

    const updated = await sql`
      UPDATE students
      SET
        full_name = ${nextName},
        email = ${nextEmail}
      WHERE id = ${auth.userId}
      RETURNING id, full_name, email, stage, grade
    `;

    const updatedUser = updated[0];

    return json(res, 200, {
      success: true,

      message:
        'تم تحديث بيانات الحساب بنجاح',

      token: createAuthToken(
        updatedUser.id
      ),

      user: {
        id: updatedUser.id,
        fullName: updatedUser.full_name,
        email: updatedUser.email,
        stage: updatedUser.stage,
        grade: updatedUser.grade,
      },
    });
  } catch (error) {
    console.error(
      'Update Profile Error:',
      error
    );

    if (error.code === '23505') {
      return json(res, 409, {
        success: false,
        error:
          'هذا الإيميل مستخدم من حساب آخر',
      });
    }

    return json(res, 500, {
      success: false,
      error:
        error.message ||
        'حدث خطأ أثناء تحديث الحساب',
    });
  }
});

// ===================== نسيت الرمز =====================

app.post(
  '/api/auth/forgot-password',
  async (req, res) => {
    try {
      const normalizedEmail = String(
        req.body?.email || ''
      )
        .trim()
        .toLowerCase();

      if (
        !normalizedEmail ||
        !normalizedEmail.includes('@')
      ) {
        return json(res, 400, {
          success: false,
          error: 'اكتب إيميل صحيح',
        });
      }

      const sql = await getSql();

      await ensureTables(sql);

      const rows = await sql`
        SELECT id
        FROM students
        WHERE email = ${normalizedEmail}
        LIMIT 1
      `;

      // لا نكشف إذا كان الإيميل مسجلًا أم لا
      if (!rows.length) {
        return json(res, 200, {
          success: true,
          message:
            'إذا كان الإيميل مسجلًا، سيصل رمز إعادة التعيين.',
        });
      }

      const code = createResetCode();

      await sql`
        UPDATE students
        SET
          reset_code_hash = ${sha256(code)},
          reset_expires_at =
            NOW() + INTERVAL '10 minutes'
        WHERE email = ${normalizedEmail}
      `;

      await sendResetEmail(
        normalizedEmail,
        code
      );

      return json(res, 200, {
        success: true,
        message:
          'تم إرسال رمز إعادة التعيين.',
      });
    } catch (error) {
      console.error(
        'Forgot Password Error:',
        error
      );

      return json(res, 500, {
        success: false,
        error:
          error.message ||
          'تعذر إرسال رمز إعادة التعيين',
      });
    }
  }
);

// ===================== إعادة تعيين الرمز =====================

app.post(
  '/api/auth/reset-password',
  async (req, res) => {
    try {
      const normalizedEmail = String(
        req.body?.email || ''
      )
        .trim()
        .toLowerCase();

      const code = String(
        req.body?.code || ''
      ).trim();

      const newPassword = String(
        req.body?.newPassword || ''
      );

      if (
        !normalizedEmail ||
        !code ||
        newPassword.length < 6
      ) {
        return json(res, 400, {
          success: false,
          error:
            'الإيميل والرمز وكلمة المرور الجديدة مطلوبة',
        });
      }

      const sql = await getSql();

      await ensureTables(sql);

      const rows = await sql`
        SELECT id
        FROM students
        WHERE email = ${normalizedEmail}
          AND reset_code_hash = ${sha256(code)}
          AND reset_expires_at > NOW()
        LIMIT 1
      `;

      if (!rows.length) {
        return json(res, 400, {
          success: false,
          error:
            'رمز التحقق غير صحيح أو منتهي',
        });
      }

      const {
        hash,
        salt,
      } = hashPassword(newPassword);

      await sql`
        UPDATE students
        SET
          password_hash = ${hash},
          password_salt = ${salt},
          reset_code_hash = NULL,
          reset_expires_at = NULL
        WHERE id = ${rows[0].id}
      `;

      return json(res, 200, {
        success: true,
        message:
          'تم تغيير الرمز بنجاح',
      });
    } catch (error) {
      console.error(
        'Reset Password Error:',
        error
      );

      return json(res, 500, {
        success: false,
        error:
          error.message ||
          'تعذر تغيير الرمز',
      });
    }
  }
);

// ===================== المساعد الذكي =====================

async function askGemini(contents) {
  if (!apiKey) {
    throw new Error(
      'GEMINI_API_KEY غير موجود'
    );
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${apiKey}`,
    {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        contents,
      }),
    }
  );

  const data = await response.json();

  if (!response.ok) {
    throw new Error(
      data?.error?.message ||
      'Gemini API request failed'
    );
  }

  return (
    data?.candidates?.[0]?.content?.parts?.[0]?.text ||
    'عذرًا، ما قدرت أطلع جواب حاليًا.'
  );
}

app.post(
  ['/chat', '/api/chat'],
  async (req, res) => {
    try {
      const {
        message,
        studentName,
        studentGrade,
        image,
        imageMimeType,
      } = req.body;

      if (
        (!message || message.trim() === '') &&
        !image
      ) {
        return res.status(400).json({
          success: false,
          error:
            'اكتب السؤال أو أرسل صورة أولًا.',
        });
      }

      const prompt = `
أنت المساعد الذكي داخل تطبيق "مساعد الطالب العراقي".

اسم الطالب: ${studentName || 'الطالب'}
الصف: ${studentGrade || 'غير محدد'}

ساعد الطالب في الدراسة بطريقة واضحة وبسيطة ومناسبة لعمره ومستواه الدراسي.

استخدم اللغة العربية، ويمكنك استخدام اللهجة العراقية بشكل بسيط عند الحاجة.

إذا كان السؤال دراسيًا:
- اشرح الحل خطوة بخطوة.
- لا تكتفِ بإعطاء الجواب النهائي.
- اجعل الشرح مناسبًا للصف الدراسي للطالب.
- إذا كانت هناك صورة لمسألة أو صفحة من كتاب، اقرأ محتواها وحاول فهم السؤال الموجود فيها.
- إذا كانت الصورة غير واضحة، أخبر الطالب بوضوح أن يعيد تصويرها.
- لا تعطِ معلومات خطرة أو غير مناسبة للأطفال.

${
  message && message.trim()
    ? `سؤال الطالب:\n${message}`
    : 'الطالب أرسل صورة ويريد المساعدة في فهمها.'
}
`;

      let contents;

      if (image) {
        const base64Data = image.includes(',')
          ? image.split(',')[1]
          : image;

        contents = [
          {
            role: 'user',

            parts: [
              {
                text: prompt,
              },

              {
                inlineData: {
                  mimeType:
                    imageMimeType ||
                    'image/jpeg',

                  data: base64Data,
                },
              },
            ],
          },
        ];
      } else {
        contents = [
          {
            role: 'user',

            parts: [
              {
                text: prompt,
              },
            ],
          },
        ];
      }

      const answer =
        await askGemini(contents);

      return res.json({
        success: true,
        answer,
      });
    } catch (error) {
      console.error(
        'Gemini Error:',
        error
      );

      return res.status(500).json({
        success: false,
        error:
          error.message ||
          'حدث خطأ أثناء الاتصال بالمساعد الذكي.',
      });
    }
  }
);

export default app;
