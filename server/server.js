import express from "express";
import OpenAI from "openai";
import dotenv from "dotenv";
import multer from "multer";
import mammoth from "mammoth";
import {
  Document,
  Packer,
  Paragraph,
  TextRun,
} from "docx";

dotenv.config();

const app = express();

app.use(express.json({ limit: "10mb" }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 20 * 1024 * 1024,
  },
});

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const PORT = process.env.PORT || 8000;

const SYSTEM_INSTRUCTIONS = `
أنت محرك تصحيح لغوي وإملائي احترافي للنصوص العربية والإنجليزية.

مهمتك الأساسية:
تصحيح الأخطاء الموجودة في النص، وليس إعادة كتابة النص كما هو.

افحص النص كلمة كلمة واكتشف:
1. الأخطاء الإملائية.
2. الحروف الناقصة أو الزائدة.
3. تبديل الحروف.
4. الأخطاء النحوية الواضحة.
5. علامات الترقيم.
6. المسافات الزائدة أو الناقصة.

أمثلة:
"السلاع عليكم" ← "السلام عليكم"
"هاذا" ← "هذا"
"المدرسه" ← "المدرسة"

مهم جدًا:

إذا كان النص باللهجة العراقية، حافظ على اللهجة العراقية ولا تحوله إلى العربية الفصحى.

هذه كلمات عراقية صحيحة حسب السياق:
شلون
شكو
ماكو
أكو
هسه
باچر
خوش
زين
هواية
إي
مو
وين
ليش
شنو
أريد
راح
دا
جاي

مثال:
"هسه اني رايح للسوك"

لا تحولها إلى:
"الآن أنا ذاهب إلى السوق"

بل حافظ على اللهجة العراقية.

لا تغير معنى النص.
لا تضف معلومات جديدة.
لا تحذف كلمات صحيحة.
لا تجعل النص رسميًا إذا كان أصله عاميًا.
لا تحول اللهجة العراقية إلى العربية الفصحى.

إذا كان النص باللغة الإنجليزية، صحح الأخطاء الإملائية والنحوية مع الحفاظ على المعنى والأسلوب.

أعد النص المصحح فقط.
لا تكتب شرحًا.
لا تكتب ملاحظات.
لا تكتب "النص المصحح:".
`;


// ===============================
// تصحيح النص العادي
// ===============================

app.post("/correct", async (req, res) => {
  try {
    const {
      text,
      language = "تلقائي",
      dialect = "iraqi",
    } = req.body ?? {};

    if (!text || typeof text !== "string") {
      return res.status(400).json({
        error: "النص فارغ",
      });
    }

    const response = await client.responses.create({
      model: process.env.OPENAI_MODEL || "gpt-5.6-mini",

      instructions: SYSTEM_INSTRUCTIONS,

      input: `
اللغة: ${language}
اللهجة: ${dialect}

افحص النص كلمة كلمة وصحح الأخطاء الإملائية والنحوية الواضحة.

النص:
${text}
`,
    });

    const correctedText = response.output_text?.trim();

    if (!correctedText) {
      return res.status(500).json({
        error: "لم يرجع المحرك نصًا مصححًا",
      });
    }

    console.log("النص الأصلي:", text);
    console.log("النص المصحح:", correctedText);

    return res.json({
      corrected_text: correctedText,
    });

  } catch (error) {
    console.error("OPENAI ERROR:", error);

    return res.status(500).json({
      error: "حدث خطأ أثناء التصحيح",
      details: error.message,
    });
  }
});


// ===============================
// تصحيح ملف Word
// ===============================

app.post(
  "/correct-word",
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          error: "لم يتم إرسال ملف Word",
        });
      }

      const language = req.body?.language || "تلقائي";
      const dialect = req.body?.dialect || "iraqi";

      console.log("استلام ملف Word:", req.file.originalname);

      // استخراج النص من ملف Word
      const result = await mammoth.extractRawText({
        buffer: req.file.buffer,
      });

      const originalText = result.value?.trim();

      if (!originalText) {
        return res.status(400).json({
          error: "ملف Word لا يحتوي على نص قابل للتصحيح",
        });
      }

      console.log("تم استخراج النص من Word");

      // إرسال النص لمحرك التصحيح
      const response = await client.responses.create({
        model: process.env.OPENAI_MODEL || "gpt-5.6-mini",

        instructions: SYSTEM_INSTRUCTIONS,

        input: `
اللغة: ${language}
اللهجة: ${dialect}

صحح النص التالي الموجود داخل ملف Word.

حافظ على:
- المعنى.
- اللهجة العراقية إذا كانت موجودة.
- الفقرات.
- علامات الترقيم.
- اللغة الأصلية.

النص:
${originalText}
`,
      });

      const correctedText = response.output_text?.trim();

      if (!correctedText) {
        return res.status(500).json({
          error: "لم يرجع المحرك نصًا مصححًا",
        });
      }

      console.log("تم تصحيح ملف Word");

      // تقسيم النص المصحح إلى فقرات
      const paragraphs = correctedText
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => line.length > 0);

      const children = paragraphs.map((paragraph) => {
        return new Paragraph({
          children: [
            new TextRun({
              text: paragraph,
            }),
          ],
        });
      });

      // إنشاء ملف Word جديد
      const document = new Document({
        sections: [
          {
            properties: {},
            children: children,
          },
        ],
      });

      const buffer = await Packer.toBuffer(document);

      console.log("تم إنشاء ملف Word المصحح");

      res.setHeader(
        "Content-Type",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      );

      res.setHeader(
        "Content-Disposition",
        'attachment; filename="corrected.docx"'
      );

      return res.send(buffer);

    } catch (error) {
      console.error("WORD ERROR:", error);

      return res.status(500).json({
        error: "حدث خطأ أثناء تصحيح ملف Word",
        details: error.message,
      });
    }
  }
);


// ===============================
// اختبار السيرفر
// ===============================

app.get("/", (req, res) => {
  res.send("Sahhaha server is running");
});


// ===============================
// تشغيل السيرفر
// ===============================

app.listen(PORT, "0.0.0.0", () => {
  console.log(
    `Sahhaha server running on http://0.0.0.0:${PORT}`
  );
});