export default function handler(req, res) {
  res.status(200).json({
    latestVersion: "1.0.0+1",
    downloadUrl: "",
    title: "تحديث جديد متوفر",
    message: "أكو تحديث جديد للتطبيق، اضغط تحديث الآن للاستفادة من الميزات الجديدة."
  });
}
