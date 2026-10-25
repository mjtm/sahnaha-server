export default function handler(req, res) {
  res.status(200).json({
latestVersion: "1.0.0+3",
downloadUrl: "https://github.com/mjtm/sahnaha-server/releases/download/v1.0.0%2B3/app-release.apk",    title: "تحديث جديد متوفر",
    message: "أكو تحديث جديد للتطبيق، اضغط تحديث الآن للاستفادة من الميزات الجديدة."
  });
}

