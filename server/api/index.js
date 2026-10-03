import cors from "cors";
import { GoogleGenerativeAI } from "@google/generative-ai";
import formidable from "formidable";
import fs from "fs";
import mammoth from "mammoth";
import {
  Document,
  Packer,
  Paragraph,
  TextRun,
} from "docx";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const SYSTEM_INSTRUCTIONS = `
أنت محرك تصحيح لغوي وإملائي احترافي للنصوص العربية والإنجليزية.

مهمتك تصحيح الأخطاء الموجودة فقط، وليس إعادة كتابة النص.

صحح:
- الأخطاء الإملائية.
- الحروف الناقصة أو الزائدة.
- تبديل الحروف.
- الأخطاء النحوية الواضحة.
- علامات الترقيم.
- المسافات الزائدة أو الناقصة.

مهم جدًا:
إذا كان النص باللهجة العراقية، حافظ على اللهجة العراقية ولا تحوله إلى الفصحى.

لا تغير معنى النص.
لا تضف معلومات.
لا تحذف كلمات صحيحة.
لا تحول اللهجة العراقية إلى العربية الفصحى.

أعد النص المصحح فقط، بدون شرح أو ملاحظات.
`;

const corsMiddleware = cors({
  origin: "*",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
});

function correctWithGemini(text, language, dialect) {
  const model = genAI.getGenerativeModel({
    model: "gemini-3.5-flash-lite",
  });

  const prompt = `
${SYSTEM_INSTRUCTIONS}

اللغة: ${language}
اللهجة: ${dialect}

صحح النص التالي:

${text}
`;

  return model.generateContent(prompt);
}

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req, res) {
  return corsMiddleware(req, res, async () => {
    try {
      if (req.method === "OPTIONS") {
        return res.status(204).end();
      }

      if (req.method === "GET") {
        return res.status(200).send(
          "Sahhaha Gemini server is running"
        );
      }

      if (req.method !== "POST") {
        return res.status(405).json({
          error: "Method not allowed",
        });
      }

      if (!process.env.GEMINI_API_KEY) {
        return res.status(500).json({
          error: "GEMINI_API_KEY غير موجود",
        });
      }

      const contentType = req.headers["content-type"] || "";

      // =========================
      // تصحيح ملف Word
      // =========================

      if (contentType.includes("multipart/form-data")) {
        const form = formidable({
          maxFileSize: 4 * 1024 * 1024,
          keepExtensions: true,
        });

        const [fields, files] = await form.parse(req);

        const uploadedFile = files.file?.[0];

        if (!uploadedFile) {
          return res.status(400).json({
            error: "لم يتم إرسال ملف Word",
          });
        }

        const language =
          fields.language?.[0] || "تلقائي";

        const dialect =
          fields.dialect?.[0] || "iraqi";

        const result = await mammoth.extractRawText({
          path: uploadedFile.filepath,
        });

        const originalText = result.value?.trim();

        if (!originalText) {
          return res.status(400).json({
            error: "ملف Word لا يحتوي على نص قابل للتصحيح",
          });
        }

        const response = await correctWithGemini(
          originalText,
          language,
          dialect
        );

        const correctedText =
          response.response.text()?.trim();

        if (!correctedText) {
          return res.status(500).json({
            error: "لم يرجع Gemini نصًا مصححًا",
          });
        }

        const paragraphs = correctedText
          .split(/\r?\n/)
          .filter((line) => line.trim());

        const children = paragraphs.map(
          (paragraph) =>
            new Paragraph({
              children: [
                new TextRun({
                  text: paragraph,
                }),
              ],
            })
        );

        const document = new Document({
          sections: [
            {
              properties: {},
              children,
            },
          ],
        });

        const buffer = await Packer.toBuffer(document);

        res.setHeader(
          "Content-Type",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        );

        res.setHeader(
          "Content-Disposition",
          'attachment; filename="corrected.docx"'
        );

        return res.send(buffer);
      }

      // =========================
      // تصحيح النص العادي
      // =========================

      let body = "";

      for await (const chunk of req) {
        body += chunk;
      }

      const data = JSON.parse(body || "{}");

      const {
        text,
        language = "تلقائي",
        dialect = "iraqi",
      } = data;

      if (!text || typeof text !== "string") {
        return res.status(400).json({
          error: "النص فارغ",
        });
      }

      const response = await correctWithGemini(
        text,
        language,
        dialect
      );

      const correctedText =
        response.response.text()?.trim();

      if (!correctedText) {
        return res.status(500).json({
          error: "لم يرجع Gemini نصًا مصححًا",
        });
      }

      res.setHeader(
        "Content-Type",
        "application/json; charset=utf-8"
      );

      return res.status(200).json({
        corrected_text: correctedText,
      });

    } catch (error) {
      console.error("SERVER ERROR:", error);

      return res.status(500).json({
        error: "حدث خطأ أثناء التصحيح",
        details: error.message,
      });
    }
  });
}