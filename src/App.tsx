/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export default function App() {
  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4 text-center font-sans" dir="rtl">
      <div className="bg-surface border border-border-main p-10 rounded-[40px] shadow-[0_25px_50px_-12px_rgba(0,0,0,0.5)] max-w-lg w-full text-text-main flex flex-col items-center">
        <div className="mb-6 flex justify-center">
          <div className="border-[3px] border-accent p-2 rounded-full">
            <svg className="w-12 h-12 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          </div>
        </div>
        <h1 className="text-2xl font-bold mb-4 tracking-tight">تم إنشاء مشروع Flutter بنجاح!</h1>
        <p className="text-text-dim mb-6 leading-relaxed">
          تم كتابة مجلدات وملفات مشروع Flutter الذي طلبته بنجاح وهو الآن جاهز في بيئة العمل. <br/>
          (يحتوي على lib و pubspec.yaml في المسار الرئيسي)
        </p>
        <div className="bg-bg border border-border-main p-6 rounded-2xl w-full text-right mb-6 text-sm text-text-dim">
          <ul className="list-disc list-inside space-y-3 marker:text-accent font-medium">
            <li>تمت إضافة حزم Firebase (Auth, Firestore, Google Sign-in).</li>
            <li>واجهة تسجيل الدخول مع Google والبريد الإلكتروني.</li>
            <li>شريط تنقل سفلي للرئيسية، ريلز، المحادثات، والملف الشخصي.</li>
            <li>تم إعداد الثيم الداكن ودعم اللغة العربية (RTL).</li>
          </ul>
        </div>
        <p className="text-xs text-accent bg-[#0095F6]/10 border border-[#0095F6]/20 py-3 px-5 rounded-xl leading-relaxed">
          لتصدير المشروع والتعديل عليه، قم بالنقر على قائمة الإعدادات (أعلى اليمين) واختيار "Export to ZIP" أو "Export to GitHub" لبدء البناء عبر أنظمة CI/CD الخاصة بك.
        </p>
      </div>
    </div>
  );
}
