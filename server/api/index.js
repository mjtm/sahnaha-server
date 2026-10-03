import cors from "cors";
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const corsMiddleware = cors({
  origin: "*",
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
});

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

أمثلة:
"السلاع عليكم" ← "السلام عليكم"
"هاذا" ← "هذا"
"المدرسه" ← "المدرسة"
"مرحيا" ← "مرحبا"
"هلز" ← "هلو"

مهم جدًا:
إذا كان النص باللهجة العراقية، حافظ على اللهجة العراقية ولا تحوله إلى الفصحى.

كلمات عراقية صحيحة حسب السياق:
شلون، شكو، ماكو، أكو، هسه، باچر، خوش، زين، هواية، إي، مو، وين، ليش، شنو، أريد، راح، دا، جاي.

لا تغير معنى النص.
لا تضف معلومات.
لا تحذف كلمات صحيحة.
لا تحول اللهجة العراقية إلى العربية الفصحى.

أعد النص المصحح فقط، بدون شرح أو ملاحظات.
`;

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

      const { text, language = "تلقائي", dialect = "iraqi" } =
        req.body ?? {};

      if (!text || typeof text !== "string") {
        return res.status(400).json({
          error: "النص فارغ",
        });
      }

      if (!process.env.GEMINI_API_KEY) {
        return res.status(500).json({
          error: "GEMINI_API_KEY غير موجود",
        });
      }

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

      const result = await model.generateContent(prompt);

      const correctedText = result.response.text()?.trim();

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
      console.error("GEMINI ERROR:", error);

      return res.status(500).json({
        error: "حدث خطأ أثناء التصحيح",
        details: error.message,
      });
    }
  });
}