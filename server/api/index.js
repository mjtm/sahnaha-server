import cors from "cors";
import { GoogleGenerativeAI } from "@google/generative-ai";

const corsMiddleware = cors({
  origin: "*",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
});

export default async function handler(req, res) {
  return corsMiddleware(req, res, async () => {
    try {
      if (req.method === "OPTIONS") {
        return res.status(204).end();
      }

      if (req.method === "GET") {
        return res.status(200).send("Sahhaha Gemini server is running");
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

      const { text, language = "تلقائي", dialect = "iraqi" } =
        req.body || {};

      if (!text || typeof text !== "string") {
        return res.status(400).json({
          error: "النص فارغ",
        });
      }

      const genAI = new GoogleGenerativeAI(
        process.env.GEMINI_API_KEY
      );

      const model = genAI.getGenerativeModel({
        model: "gemini-3.5-flash-lite",
      });

      const prompt = `
أنت محرك تصحيح لغوي وإملائي احترافي للنصوص العربية والإنجليزية.

صحح الأخطاء الموجودة فقط، ولا تعيد كتابة النص.

صحح:
- الأخطاء الإملائية.
- الحروف الناقصة أو الزائدة.
- تبديل الحروف.
- الأخطاء النحوية الواضحة.
- علامات الترقيم.
- المسافات.

إذا كان النص باللهجة العراقية، حافظ على اللهجة العراقية ولا تحوله إلى الفصحى.

لا تغير المعنى.
لا تضف معلومات.
لا تحذف كلمات صحيحة.

أعد النص المصحح فقط، بدون شرح.

اللغة: ${language}
اللهجة: ${dialect}

النص:
${text}
`;

      const result = await model.generateContent(prompt);

      const correctedText = result.response.text().trim();

      if (!correctedText) {
        return res.status(500).json({
          error: "لم يرجع Gemini نصًا مصححًا",
        });
      }

      return res.status(200).json({
        corrected_text: correctedText,
      });
    } catch (error) {
      console.error("GEMINI ERROR:", error);

      return res.status(500).json({
        error: "حدث خطأ أثناء التصحيح",
        details: error.message,
      });
    }
  });
}