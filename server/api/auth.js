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
const NYLAS_SENDER_EMAIL = process.env.NYLAS_SENDER_EMAIL || 'no-reply@sahhaha-app.nylas.email';
const AUTH_SECRET = process.env.AUTH_SECRET;

if (!apiKey) console.error('GEMINI_API_KEY غير موجود');
if (!DATABASE_URL) console.error('DATABASE_URL غير موجود');
if (!NYLAS_API_KEY) console.error('NYLAS_API_KEY غير موجود');
if (!AUTH_SECRET) console.error('AUTH_SECRET غير موجود');

let sqlPromise;

async function getSql() {
  if (!DATABASE_URL) {
    throw new Error('DATABASE_URL ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪» ┘ü┘è Vercel Environment Variables');
  }
  if (!sqlPromise) {
    sqlPromise = import('@neondatabase/serverless').then(({ neon }) => neon(DATABASE_URL));
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

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return { hash, salt };
}

function verifyPassword(password, hash, salt) {
  const derived = crypto.scryptSync(password, salt, 64);
  const stored = Buffer.from(hash, 'hex');
  return stored.length === derived.length &&
    crypto.timingSafeEqual(stored, derived);
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
    throw new Error('AUTH_SECRET ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»');
  }

  const header = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = base64Url(JSON.stringify({
    sub: String(userId),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60),
  }));

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
        .padEnd(Math.ceil(String(value).length / 4) * 4, '=');

      return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
    };

    const data = decodeBase64Url(payload);

    if (!data?.sub || !data?.exp || Number(data.exp) <= Math.floor(Date.now() / 1000)) {
      return null;
    }

    return { userId: String(data.sub) };
  } catch (_) {
    return null;
  }
}

function getAuthToken(req) {
  const header = req.headers?.authorization || '';
  if (!header.toLowerCase().startsWith('bearer ')) return null;
  return header.slice(7).trim();
}

async function sendResetEmail(email, code) {
  if (!NYLAS_API_KEY) {
    throw new Error('NYLAS_API_KEY غير موجود في Vercel Environment Variables');
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
            <p>رمز إعادة التعيين الخاص بحسابك في <b>المصحح الذكي</b> هو:</p>
            <div style="font-size:32px;font-weight:bold;letter-spacing:8px;margin:20px 0">
              ${code}
            </div>
            <p>الرمز صالح لمدة 10 دقائق فقط.</p>
            <p>إذا لم تطلب إعادة التعيين، يمكنك تجاهل هذه الرسالة.</p>
          </div>
        `,
      }),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`فشل إرسال الإيميل عبر Nylas: ${text}`);
  }
}

function validateRegisterInput({ fullName, email, password, stage, grade }) {
  if (!fullName || !email || !password || !stage || !grade) {
    return '╪¼┘à┘è╪╣ ╪º┘ä╪¡┘é┘ê┘ä ┘à╪╖┘ä┘ê╪¿╪⌐';
  }

  if (String(fullName).trim().split(/\s+/).length < 3) {
    return '╪º┘â╪¬╪¿ ╪º┘ä╪º╪│┘à ╪º┘ä╪½┘ä╪º╪½┘è';
  }

  if (!String(email).includes('@')) {
    return '╪º┘â╪¬╪¿ ╪Ñ┘è┘à┘è┘ä ╪╡╪¡┘è╪¡';
  }

  if (String(password).length < 6) {
    return '╪º┘ä╪▒┘à╪▓ ┘è╪¼╪¿ ╪ú┘å ┘è┘â┘ê┘å 6 ╪ú╪¡╪▒┘ü ╪ú┘ê ╪ú╪▒┘é╪º┘à ╪╣┘ä┘ë ╪º┘ä╪ú┘é┘ä';
  }

  if (!['primary', 'middle'].includes(stage)) {
    return '╪º┘ä┘à╪▒╪¡┘ä╪⌐ ╪º┘ä╪»╪▒╪º╪│┘è╪⌐ ╪║┘è╪▒ ╪╡╪¡┘è╪¡╪⌐';
  }

  return null;
}

// ╪º┘ä╪╡┘ü╪¡╪⌐ ╪º┘ä╪▒╪ª┘è╪│┘è╪⌐
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '╪│┘è╪▒┘ü╪▒ ┘à╪│╪º╪╣╪» ╪º┘ä╪╖╪º┘ä╪¿ ╪º┘ä╪╣╪▒╪º┘é┘è ┘è╪╣┘à┘ä ╪¿┘å╪¼╪º╪¡ ≡ƒñû',
  });
});

// ===================== ╪º┘ä╪¡╪│╪º╪¿╪º╪¬ =====================

app.post('/api/auth/register', async (req, res) => {
  try {
    const { fullName, email, password, stage, grade } = req.body || {};
    const validationError = validateRegisterInput({
      fullName, email, password, stage, grade,
    });

    if (validationError) {
      return json(res, 400, { success: false, error: validationError });
    }

    const sql = await getSql();
    await ensureTables(sql);

    const normalizedEmail = String(email).trim().toLowerCase();

    const existing = await sql`
      SELECT id FROM students
      WHERE email = ${normalizedEmail}
      LIMIT 1
    `;

    if (existing.length) {
      return json(res, 409, {
        success: false,
        error: '┘ç╪░╪º ╪º┘ä╪Ñ┘è┘à┘è┘ä ┘à╪│╪¼┘ä ┘à╪│╪¿┘é╪º┘ï',
      });
    }

    const { hash, salt } = hashPassword(String(password));

    const rows = await sql`
      INSERT INTO students
        (full_name, email, password_hash, password_salt, stage, grade)
      VALUES
        (${String(fullName).trim()}, ${normalizedEmail}, ${hash}, ${salt}, ${stage}, ${grade})
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
      error: error.message || '╪¡╪»╪½ ╪«╪╖╪ú ╪ú╪½┘å╪º╪í ╪Ñ┘å╪┤╪º╪í ╪º┘ä╪¡╪│╪º╪¿',
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const normalizedEmail = String(email || '').trim().toLowerCase();

    if (!normalizedEmail || !password) {
      return json(res, 400, {
        success: false,
        error: '╪º┘ä╪Ñ┘è┘à┘è┘ä ┘ê╪º┘ä╪▒┘à╪▓ ┘à╪╖┘ä┘ê╪¿╪º┘å',
      });
    }

    const sql = await getSql();
    await ensureTables(sql);

    const rows = await sql`
      SELECT id, full_name, email, password_hash, password_salt, stage, grade
      FROM students
      WHERE email = ${normalizedEmail}
      LIMIT 1
    `;

    if (!rows.length ||
        !verifyPassword(
          String(password),
          rows[0].password_hash,
          rows[0].password_salt
        )) {
      return json(res, 401, {
        success: false,
        error: '╪º┘ä╪Ñ┘è┘à┘è┘ä ╪ú┘ê ╪º┘ä╪▒┘à╪▓ ╪║┘è╪▒ ╪╡╪¡┘è╪¡',
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
      error: error.message || '╪¡╪»╪½ ╪«╪╖╪ú ╪ú╪½┘å╪º╪í ╪¬╪│╪¼┘è┘ä ╪º┘ä╪»╪«┘ê┘ä',
    });
  }
});


// ╪¬╪¡╪»┘è╪½ ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪¡╪│╪º╪¿: ╪º┘ä╪º╪│┘à + ╪º┘ä╪Ñ┘è┘à┘è┘ä + ╪º┘ä╪▒┘à╪▓
app.post('/api/auth/update-profile', async (req, res) => {
  try {
    const auth = verifyAuthToken(getAuthToken(req));

    if (!auth) {
      return json(res, 401, {
        success: false,
        error: '╪¼┘ä╪│╪⌐ ╪º┘ä╪»╪«┘ê┘ä ╪║┘è╪▒ ╪╡╪º┘ä╪¡╪⌐ ╪ú┘ê ┘à┘å╪¬┘ç┘è╪⌐╪î ╪│╪¼┘ä ╪º┘ä╪»╪«┘ê┘ä ┘à╪▒╪⌐ ╪½╪º┘å┘è╪⌐',
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
        error: '╪ú╪»╪«┘ä ╪º┘ä╪▒┘à╪▓ ╪º┘ä╪¡╪º┘ä┘è ┘ä┘ä╪¬╪ú┘â┘è╪»',
      });
    }

    const sql = await getSql();
    await ensureTables(sql);

    const rows = await sql`
      SELECT id, full_name, email, password_hash, password_salt, stage, grade
      FROM students
      WHERE id = ${auth.userId}
      LIMIT 1
    `;

    if (!rows.length) {
      return json(res, 404, {
        success: false,
        error: '╪º┘ä╪¡╪│╪º╪¿ ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»',
      });
    }

    const user = rows[0];

    if (!verifyPassword(
      String(currentPassword),
      user.password_hash,
      user.password_salt
    )) {
      return json(res, 401, {
        success: false,
        error: '╪º┘ä╪▒┘à╪▓ ╪º┘ä╪¡╪º┘ä┘è ╪║┘è╪▒ ╪╡╪¡┘è╪¡',
      });
    }

    const nextName = String(fullName ?? user.full_name).trim();
    const nextEmail = String(email ?? user.email).trim().toLowerCase();
    const nextPassword = newPassword == null ? '' : String(newPassword);

    if (nextName.split(/\s+/).filter(Boolean).length < 3) {
      return json(res, 400, {
        success: false,
        error: '╪º┘â╪¬╪¿ ╪º┘ä╪º╪│┘à ╪º┘ä╪½┘ä╪º╪½┘è',
      });
    }

    if (!nextEmail.includes('@')) {
      return json(res, 400, {
        success: false,
        error: '╪º┘â╪¬╪¿ ╪Ñ┘è┘à┘è┘ä ╪╡╪¡┘è╪¡',
      });
    }

    if (newPassword != null && nextPassword.length > 0 && nextPassword.length < 6) {
      return json(res, 400, {
        success: false,
        error: '╪º┘ä╪▒┘à╪▓ ╪º┘ä╪¼╪»┘è╪» ┘è╪¼╪¿ ╪ú┘å ┘è┘â┘ê┘å 6 ╪ú╪¡╪▒┘ü ╪ú┘ê ╪ú╪▒┘é╪º┘à ╪╣┘ä┘ë ╪º┘ä╪ú┘é┘ä',
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
          error: '┘ç╪░╪º ╪º┘ä╪Ñ┘è┘à┘è┘ä ┘à╪│╪¬╪«╪»┘à ┘à┘å ╪¡╪│╪º╪¿ ╪ó╪«╪▒',
        });
      }
    }

    if (newPassword != null && nextPassword.length > 0) {
      const { hash, salt } = hashPassword(nextPassword);

      const updated = await sql`
        UPDATE students
        SET full_name = ${nextName},
            email = ${nextEmail},
            password_hash = ${hash},
            password_salt = ${salt}
        WHERE id = ${auth.userId}
        RETURNING id, full_name, email, stage, grade
      `;

      const updatedUser = updated[0];

      return json(res, 200, {
        success: true,
        message: '╪¬┘à ╪¬╪¡╪»┘è╪½ ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪¡╪│╪º╪¿ ┘ê╪º┘ä╪▒┘à╪▓ ╪¿┘å╪¼╪º╪¡',
        token: createAuthToken(updatedUser.id),
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
      SET full_name = ${nextName},
          email = ${nextEmail}
      WHERE id = ${auth.userId}
      RETURNING id, full_name, email, stage, grade
    `;

    const updatedUser = updated[0];

    return json(res, 200, {
      success: true,
      message: '╪¬┘à ╪¬╪¡╪»┘è╪½ ╪¿┘è╪º┘å╪º╪¬ ╪º┘ä╪¡╪│╪º╪¿ ╪¿┘å╪¼╪º╪¡',
      token: createAuthToken(updatedUser.id),
      user: {
        id: updatedUser.id,
        fullName: updatedUser.full_name,
        email: updatedUser.email,
        stage: updatedUser.stage,
        grade: updatedUser.grade,
      },
    });
  } catch (error) {
    console.error('Update Profile Error:', error);

    if (error.code === '23505') {
      return json(res, 409, {
        success: false,
        error: '┘ç╪░╪º ╪º┘ä╪Ñ┘è┘à┘è┘ä ┘à╪│╪¬╪«╪»┘à ┘à┘å ╪¡╪│╪º╪¿ ╪ó╪«╪▒',
      });
    }

    return json(res, 500, {
      success: false,
      error: error.message || '╪¡╪»╪½ ╪«╪╖╪ú ╪ú╪½┘å╪º╪í ╪¬╪¡╪»┘è╪½ ╪º┘ä╪¡╪│╪º╪¿',
    });
  }
});

app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const normalizedEmail = String(req.body?.email || '').trim().toLowerCase();

    if (!normalizedEmail || !normalizedEmail.includes('@')) {
      return json(res, 400, {
        success: false,
        error: '╪º┘â╪¬╪¿ ╪Ñ┘è┘à┘è┘ä ╪╡╪¡┘è╪¡',
      });
    }

    const sql = await getSql();
    await ensureTables(sql);

    const rows = await sql`
      SELECT id FROM students
      WHERE email = ${normalizedEmail}
      LIMIT 1
    `;

    // ┘ä╪º ┘å┘â╪┤┘ü ╪Ñ╪░╪º ┘â╪º┘å ╪º┘ä╪Ñ┘è┘à┘è┘ä ┘à╪│╪¼┘ä╪º┘ï ╪ú┘ê ┘ä╪º.
    if (!rows.length) {
      return json(res, 200, {
        success: true,
        message: '╪Ñ╪░╪º ┘â╪º┘å ╪º┘ä╪Ñ┘è┘à┘è┘ä ┘à╪│╪¼┘ä╪º┘ï╪î ╪│┘è╪╡┘ä ╪▒┘à╪▓ ╪Ñ╪╣╪º╪»╪⌐ ╪º┘ä╪¬╪╣┘è┘è┘å.',
      });
    }

    const code = createResetCode();

    await sql`
      UPDATE students
      SET reset_code_hash = ${sha256(code)},
          reset_expires_at = NOW() + INTERVAL '10 minutes'
      WHERE email = ${normalizedEmail}
    `;

    await sendResetEmail(normalizedEmail, code);

    return json(res, 200, {
      success: true,
      message: '╪¬┘à ╪Ñ╪▒╪│╪º┘ä ╪▒┘à╪▓ ╪Ñ╪╣╪º╪»╪⌐ ╪º┘ä╪¬╪╣┘è┘è┘å.',
    });
  } catch (error) {
    console.error('Forgot Password Error:', error);
    return json(res, 500, {
      success: false,
      error: error.message || '╪¬╪╣╪░╪▒ ╪Ñ╪▒╪│╪º┘ä ╪▒┘à╪▓ ╪Ñ╪╣╪º╪»╪⌐ ╪º┘ä╪¬╪╣┘è┘è┘å',
    });
  }
});

app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const normalizedEmail = String(req.body?.email || '').trim().toLowerCase();
    const code = String(req.body?.code || '').trim();
    const newPassword = String(req.body?.newPassword || '');

    if (!normalizedEmail || !code || newPassword.length < 6) {
      return json(res, 400, {
        success: false,
        error: '╪º┘ä╪Ñ┘è┘à┘è┘ä ┘ê╪º┘ä╪▒┘à╪▓ ┘ê┘â┘ä┘à╪⌐ ╪º┘ä┘à╪▒┘ê╪▒ ╪º┘ä╪¼╪»┘è╪»╪⌐ ┘à╪╖┘ä┘ê╪¿╪⌐',
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
        error: '╪▒┘à╪▓ ╪º┘ä╪¬╪¡┘é┘é ╪║┘è╪▒ ╪╡╪¡┘è╪¡ ╪ú┘ê ┘à┘å╪¬┘ç┘è',
      });
    }

    const { hash, salt } = hashPassword(newPassword);

    await sql`
      UPDATE students
      SET password_hash = ${hash},
          password_salt = ${salt},
          reset_code_hash = NULL,
          reset_expires_at = NULL
      WHERE id = ${rows[0].id}
    `;

    return json(res, 200, {
      success: true,
      message: '╪¬┘à ╪¬╪║┘è┘è╪▒ ╪º┘ä╪▒┘à╪▓ ╪¿┘å╪¼╪º╪¡',
    });
  } catch (error) {
    console.error('Reset Password Error:', error);
    return json(res, 500, {
      success: false,
      error: error.message || '╪¬╪╣╪░╪▒ ╪¬╪║┘è┘è╪▒ ╪º┘ä╪▒┘à╪▓',
    });
  }
});

// ===================== ╪º┘ä┘à╪│╪º╪╣╪» ╪º┘ä╪░┘â┘è =====================

async function askGemini(contents) {
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY ╪║┘è╪▒ ┘à┘ê╪¼┘ê╪»');
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
    '╪╣╪░╪▒╪º┘ï╪î ┘à╪º ┘é╪»╪▒╪¬ ╪ú╪╖┘ä╪╣ ╪¼┘ê╪º╪¿ ╪¡╪º┘ä┘è╪º┘ï.'
  );
}

app.post(['/chat', '/api/chat'], async (req, res) => {
  try {
    const {
      message,
      studentName,
      studentGrade,
      image,
      imageMimeType,
    } = req.body;

    if ((!message || message.trim() === '') && !image) {
      return res.status(400).json({
        success: false,
        error: '╪º┘â╪¬╪¿ ╪º┘ä╪│╪ñ╪º┘ä ╪ú┘ê ╪ú╪▒╪│┘ä ╪╡┘ê╪▒╪⌐ ╪ú┘ê┘ä╪º┘ï',
      });
    }

    const prompt = `
╪ú┘å╪¬ ╪º┘ä┘à╪│╪º╪╣╪» ╪º┘ä╪░┘â┘è ╪»╪º╪«┘ä ╪¬╪╖╪¿┘è┘é "┘à╪│╪º╪╣╪» ╪º┘ä╪╖╪º┘ä╪¿ ╪º┘ä╪╣╪▒╪º┘é┘è".

╪º╪│┘à ╪º┘ä╪╖╪º┘ä╪¿: ${studentName || '╪º┘ä╪╖╪º┘ä╪¿'}
╪º┘ä╪╡┘ü: ${studentGrade || '╪║┘è╪▒ ┘à╪¡╪»╪»'}

╪│╪º╪╣╪» ╪º┘ä╪╖╪º┘ä╪¿ ┘ü┘è ╪º┘ä╪»╪▒╪º╪│╪⌐ ╪¿╪╖╪▒┘è┘é╪⌐ ┘ê╪º╪╢╪¡╪⌐ ┘ê╪¿╪│┘è╪╖╪⌐ ┘ê┘à┘å╪º╪│╪¿╪⌐ ┘ä╪╣┘à╪▒┘ç ┘ê┘à╪│╪¬┘ê╪º┘ç ╪º┘ä╪»╪▒╪º╪│┘è.

╪º╪│╪¬╪«╪»┘à ╪º┘ä┘ä╪║╪⌐ ╪º┘ä╪╣╪▒╪¿┘è╪⌐╪î ┘ê┘è┘à┘â┘å┘â ╪º╪│╪¬╪«╪»╪º┘à ╪º┘ä┘ä┘ç╪¼╪⌐ ╪º┘ä╪╣╪▒╪º┘é┘è╪⌐ ╪¿╪┤┘â┘ä ╪¿╪│┘è╪╖ ╪╣┘å╪» ╪º┘ä╪¡╪º╪¼╪⌐.

╪Ñ╪░╪º ┘â╪º┘å ╪º┘ä╪│╪ñ╪º┘ä ╪»╪▒╪º╪│┘è╪º┘ï:
- ╪º╪┤╪▒╪¡ ╪º┘ä╪¡┘ä ╪«╪╖┘ê╪⌐ ╪¿╪«╪╖┘ê╪⌐.
- ┘ä╪º ╪¬┘â╪¬┘ü┘É ╪¿╪Ñ╪╣╪╖╪º╪í ╪º┘ä╪¼┘ê╪º╪¿ ╪º┘ä┘å┘ç╪º╪ª┘è.
- ╪º╪¼╪╣┘ä ╪º┘ä╪┤╪▒╪¡ ┘à┘å╪º╪│╪¿╪º┘ï ┘ä┘ä╪╡┘ü ╪º┘ä╪»╪▒╪º╪│┘è ┘ä┘ä╪╖╪º┘ä╪¿.
- ╪Ñ╪░╪º ┘â╪º┘å╪¬ ┘ç┘å╪º┘â ╪╡┘ê╪▒╪⌐ ┘ä┘à╪│╪ú┘ä╪⌐ ╪ú┘ê ╪╡┘ü╪¡╪⌐ ┘à┘å ┘â╪¬╪º╪¿╪î ╪º┘é╪▒╪ú ┘à╪¡╪¬┘ê╪º┘ç╪º ┘ê╪¡╪º┘ê┘ä ┘ü┘ç┘à ╪º┘ä╪│╪ñ╪º┘ä ╪º┘ä┘à┘ê╪¼┘ê╪» ┘ü┘è┘ç╪º.
- ╪Ñ╪░╪º ┘â╪º┘å╪¬ ╪º┘ä╪╡┘ê╪▒╪⌐ ╪║┘è╪▒ ┘ê╪º╪╢╪¡╪⌐╪î ╪ú╪«╪¿╪▒ ╪º┘ä╪╖╪º┘ä╪¿ ╪¿┘ê╪╢┘ê╪¡ ╪ú┘å ┘è╪╣┘è╪» ╪¬╪╡┘ê┘è╪▒┘ç╪º.

┘ä╪º ╪¬╪╣╪╖┘É ┘à╪╣┘ä┘ê┘à╪º╪¬ ╪«╪╖╪▒╪⌐ ╪ú┘ê ╪║┘è╪▒ ┘à┘å╪º╪│╪¿╪⌐ ┘ä┘ä╪ú╪╖┘ü╪º┘ä.

${
  message && message.trim()
    ? `╪│╪ñ╪º┘ä ╪º┘ä╪╖╪º┘ä╪¿:\n${message}`
    : '╪º┘ä╪╖╪º┘ä╪¿ ╪ú╪▒╪│┘ä ╪╡┘ê╪▒╪⌐ ┘ê┘è╪▒┘è╪» ╪º┘ä┘à╪│╪º╪╣╪»╪⌐ ┘ü┘è ┘ü┘ç┘à┘ç╪º.'
}
`;

    let contents;

    if (image) {
      const base64Data = image.includes(',')
        ? image.split(',')[1]
        : image;

      contents = [{
        role: 'user',
        parts: [
          { text: prompt },
          {
            inlineData: {
              mimeType: imageMimeType || 'image/jpeg',
              data: base64Data,
            },
          },
        ],
      }];
    } else {
      contents = [{
        role: 'user',
        parts: [{ text: prompt }],
      }];
    }

    const answer = await askGemini(contents);

    return res.json({
      success: true,
      answer,
    });
  } catch (error) {
    console.error('Gemini Error:', error);

    return res.status(500).json({
      success: false,
      error: error.message ||
        '╪¡╪»╪½ ╪«╪╖╪ú ╪ú╪½┘å╪º╪í ╪º┘ä╪º╪¬╪╡╪º┘ä ╪¿╪º┘ä┘à╪│╪º╪╣╪» ╪º┘ä╪░┘â┘è.',
    });
  }
});

export default app;


