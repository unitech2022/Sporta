namespace SportaApis.Data;

/// <summary>
/// The official Terms &amp; Conditions, Privacy Policy, and Refund Policy content,
/// in Arabic and English, stored as lightweight Markdown (## section headings,
/// ### sub-headings, and - bullets). Seeded into the <c>SystemSetting</c> keys
/// (terms_conditions / privacy_policy / refund_policy) that the app and admin
/// dashboard already read/write. Bump <see cref="Version"/> whenever the text
/// below changes so <c>DbSeeder.UpgradePoliciesAsync</c> re-applies it to
/// existing databases (admin edits made after an upgrade are preserved until the
/// next version bump).
/// </summary>
public static class PolicyContent
{
    public const int Version = 5;

    /// <summary>(key, nameAr, nameEn, valueAr, valueEn) for each policy.</summary>
    public static readonly (string Key, string NameAr, string NameEn, string ValueAr, string ValueEn)[] Policies =
    {
        ("terms_conditions", "الشروط والأحكام", "Terms & Conditions", TermsAr, TermsEn),
        ("privacy_policy", "سياسة الخصوصية", "Privacy Policy", PrivacyAr, PrivacyEn),
        ("refund_policy", "سياسة الاسترجاع", "Refund Policy", RefundAr, RefundEn),
    };

    // ── Terms & Conditions ──────────────────────────────────────────────────

    public const string TermsEn = """
## 1. Acceptance of These Terms

These Terms and Conditions ("Terms") form a binding agreement between you ("User", "you") and Sporta ("Sporta", "we", "us", "our"), the operator of the Sporta mobile application and website (together, the "Platform"). By creating an account, browsing, or using the Platform in any way, you confirm that you have read, understood, and agree to be bound by these Terms and by our Privacy Policy and Refund Policy, which are incorporated by reference.

If you do not agree to these Terms, please do not access or use the Platform. We may update these Terms from time to time as described in Section 14; continued use of the Platform after changes take effect constitutes acceptance of the revised Terms.

## 2. About Sporta

Sporta is a digital platform that allows users to discover and book sports courts, fields, and facilities (including but not limited to padel, football/five-a-side, tennis, and other sports), book certified coaches and trainers, organize or join matches, and manage related payments and schedules.

Sporta acts as an intermediary connecting Users with independent venues, facility owners, clubs, and coaches ("Partners"). Sporta does not itself own or operate the sports venues or employ the coaches listed on the Platform unless expressly stated otherwise.

## 3. Eligibility and Account Registration

To use the Platform you must be at least 18 years old, or be using the Platform under the supervision and with the consent of a parent or legal guardian who accepts these Terms on your behalf.

You agree to provide accurate, current, and complete information when creating your account and to keep this information updated. You are solely responsible for maintaining the confidentiality of your login credentials and for all activity that occurs under your account.

- You must notify us immediately of any unauthorized use of your account.

- Sporta reserves the right to suspend or terminate accounts that contain false, misleading, or outdated information.

- One account may not be shared between multiple individuals for the purpose of circumventing usage limits or promotions.

## 4. Bookings and Payments

The Platform allows you to reserve time slots at courts and facilities and to book sessions with coaches, subject to real-time availability provided by our Partners. A booking is only confirmed once you receive a confirmation notification and, where applicable, payment has been successfully processed.

Prices displayed on the Platform are set by the relevant venue or coach and may include a Sporta service fee, which will be disclosed to you before you confirm payment. All prices are shown inclusive of applicable VAT unless stated otherwise.

- Payments may be made via the payment methods enabled on the Platform (credit/debit card, digital wallet, or other supported methods).

- You authorize Sporta and its payment processors to charge the applicable amount to your selected payment method at the time of booking.

- Group or split-payment bookings are subject to the specific rules described at the time of booking; Sporta is not responsible for collecting outstanding shares between participants.

## 5. Cancellations and Refunds

Cancellations, rescheduling, and refunds are governed by our Refund Policy, which forms an integral part of these Terms. Refund eligibility depends on the timing of your cancellation, the specific venue or coach policy, and the type of booking made. Please review the Refund Policy carefully before booking.

## 6. User Conduct and Responsibilities

When using the Platform and attending bookings, you agree to:

- Arrive on time and comply with the rules, safety instructions, and code of conduct of the venue or coach.

- Treat other Users, venue staff, and coaches with respect and refrain from abusive, discriminatory, or unlawful behavior.

- Use the facilities and equipment only for their intended purpose and take reasonable care to avoid damage.

- Not use the Platform for any fraudulent, unlawful, or unauthorized commercial purpose, including reselling bookings without authorization.

Violation of this section may result in suspension or termination of your account and, where applicable, liability for damages caused.

## 7. Health, Safety, and Assumption of Risk

Participation in sports and physical activities booked through the Platform carries inherent risks of injury. By booking and participating in any match, training session, or activity through Sporta, you confirm that you are physically fit to participate and voluntarily assume all risks associated with such participation.

Sporta strongly recommends that Users consult a physician before beginning any new physical activity, particularly if they have pre-existing medical conditions. Sporta is not a medical provider and does not offer medical advice.

To the maximum extent permitted by law, Sporta is not liable for any injury, illness, death, or property damage arising from participation in activities booked through the Platform.

## 8. Venue and Coach Partners

Venues, facilities, and coaches listed on the Platform are independent third parties and are solely responsible for the accuracy of their listings, the condition and safety of their facilities, and the quality of the services and coaching they provide.

Sporta takes reasonable steps to verify Partner information but does not guarantee the accuracy, completeness, or reliability of any listing, review, or rating. Disputes regarding the quality of a venue, facility, or coaching session should first be raised with the relevant Partner and, where necessary, escalated to Sporta support for mediation.

## 9. Intellectual Property

All content on the Platform, including the Sporta name, logo, design, software, graphics, and text, is the property of Sporta or its licensors and is protected by applicable intellectual property laws. You may not copy, modify, distribute, or create derivative works from any part of the Platform without our prior written consent.

Any content you submit to the Platform (such as reviews, photos, or match results) remains your property, but by submitting it you grant Sporta a worldwide, royalty-free, non-exclusive license to use, display, and distribute that content in connection with operating and promoting the Platform.

## 10. Indemnification

You agree to indemnify and hold harmless Sporta, its officers, employees, and affiliates from any claims, damages, losses, or expenses (including reasonable legal fees) arising from your breach of these Terms, your misuse of the Platform, or your violation of any applicable law or third-party right.

## 11. Suspension and Termination

Sporta may suspend or terminate your access to the Platform, with or without notice, if you breach these Terms, engage in fraudulent or unlawful activity, or pose a risk to other Users, Partners, or the Platform itself.

You may close your account at any time through the app settings or by contacting our support team. Termination does not affect any rights or obligations that accrued prior to termination, including outstanding payment obligations.

## 12. Privacy

Your use of the Platform is also governed by our Privacy Policy, which explains how we collect, use, share, and protect your personal data. Please review it carefully.

## 13. Modifications to These Terms

We may amend these Terms from time to time to reflect changes in our services, legal requirements, or business practices. Material changes will be communicated through the Platform or by WhatsApp message at least seven (7) days before they take effect. Your continued use of the Platform after the effective date constitutes acceptance of the amended Terms.

## 14. Governing Law and Dispute Resolution

These Terms are governed by, and shall be construed in accordance with, the laws of the Kingdom of Saudi Arabia. Any dispute arising out of or in connection with these Terms shall first be addressed through good-faith negotiation between the parties; if unresolved, it shall be submitted to the competent courts of the Kingdom of Saudi Arabia.

## 15. Contact Us

If you have any questions about these Terms, please contact us at:

- Email: support@sportaapp.net

- In-App Messaging
""";

    public const string TermsAr = """
## ١. الموافقة على هذه الشروط

تشكل هذه الشروط والأحكام ("الشروط") اتفاقية ملزمة بينك ("المستخدم"، "أنت") وبين سبورتا ("سبورتا"، "نحن")، مشغّل تطبيق وموقع سبورتا (يُشار إليهما معًا بـ"التطبيق"). من خلال إنشاء حساب أو تصفح التطبيق أو استخدامها بأي شكل، فإنك تقر بأنك قرأت هذه الشروط وسياسة الخصوصية وسياسة الاسترجاع الخاصة بنا، وفهمتها، وتوافق على الالتزام بها، وتُعد هذه السياسات جزءًا لا يتجزأ من هذه الشروط.

في حال عدم موافقتك على هذه الشروط، يُرجى عدم الدخول إلى التطبيق أو استخدامها. قد نقوم بتحديث هذه الشروط من وقت لآخر وفق ما هو موضح في البند 14؛ ويُعد استمرارك في استخدام التطبيق بعد سريان أي تعديل بمثابة موافقة على الشروط المعدّلة.

## ٢. عن سبورتا

سبورتا تطبيق رقمي يتيح للمستخدمين اكتشاف وحجز ملاعب ومرافق رياضية (تشمل على سبيل المثال لا الحصر: البادل، كرة القدم الخماسية والسباعية، التنس، وغيرها من الرياضات)، وحجز مدربين معتمدين، وتنظيم المباريات أو الانضمام إليها، وإدارة المدفوعات والمواعيد المرتبطة بذلك.

تعمل سبورتا كوسيط يربط المستخدمين بالملاعب والمرافق ومالكيها والأندية والمدربين المستقلين ("الشركاء"). لا تمتلك سبورتا أو تُشغّل المرافق الرياضية المدرجة على التطبيق، ولا توظّف المدربين، ما لم يُنص على خلاف ذلك صراحة.

## ٣. الأهلية وتسجيل الحساب

لاستخدام التطبيق، يجب أن يكون عمرك 18 عامًا على الأقل، أو أن تستخدم التطبيق تحت إشراف وموافقة أحد الوالدين أو ولي الأمر الشرعي الذي يقبل هذه الشروط نيابة عنك.

توافق على تقديم معلومات دقيقة وحديثة وكاملة عند إنشاء حسابك، وعلى تحديث هذه المعلومات باستمرار. أنت المسؤول الوحيد عن الحفاظ على سرية بيانات الدخول الخاصة بك وعن جميع الأنشطة التي تتم من خلال حسابك.

- يجب عليك إخطارنا فورًا في حال أي استخدام غير مصرح به لحسابك.

- تحتفظ سبورتا بالحق في تعليق أو إنهاء الحسابات التي تحتوي على معلومات كاذبة أو مضللة أو غير محدّثة.

- لا يجوز مشاركة حساب واحد بين عدة أفراد بهدف الالتفاف على حدود الاستخدام أو العروض الترويجية.

## ٤. الحجوزات والمدفوعات

يتيح لك التطبيق حجز أوقات في الملاعب والمرافق، وحجز حصص مع المدربين، وفقًا للتوفر الفعلي الذي يوفره شركاؤنا. لا يُعد الحجز مؤكدًا إلا بعد استلامك إشعار تأكيد، وعند الاقتضاء، بعد إتمام عملية الدفع بنجاح.

يتم تحديد الأسعار المعروضة على التطبيق من قِبل الملعب أو المدرب المعني، وقد تشمل رسوم خدمة تُحصّلها سبورتا، ويتم الإفصاح عنها لك قبل تأكيد الدفع. جميع الأسعار المعروضة شاملة ضريبة القيمة المضافة ما لم يُذكر خلاف ذلك.

- يمكن الدفع من خلال وسائل الدفع المتاحة على التطبيق (بطاقة ائتمان/خصم، محفظة رقمية، أو وسائل أخرى مدعومة).

- أنت تفوّض سبورتا ومزودي خدمة الدفع لديها بتحصيل المبلغ المستحق من وسيلة الدفع التي اخترتها عند الحجز.

- تخضع الحجوزات الجماعية أو المقسّمة الدفع للقواعد المحددة الموضحة عند الحجز؛ ولا تتحمل سبورتا مسؤولية تحصيل الحصص المستحقة بين المشاركين.

## ٥. الإلغاء والاسترجاع

تخضع عمليات الإلغاء وإعادة الجدولة والاسترجاع لسياسة الاسترجاع الخاصة بنا، والتي تُعد جزءًا لا يتجزأ من هذه الشروط. تعتمد أهلية الاسترجاع على توقيت الإلغاء، وسياسة الملعب أو المدرب المحددة، ونوع الحجز. يُرجى مراجعة سياسة الاسترجاع بعناية قبل الحجز.

## ٦. سلوك المستخدم ومسؤولياته

عند استخدام التطبيق وحضور الحجوزات، توافق على:

- الحضور في الوقت المحدد والالتزام بقواعد وتعليمات السلامة وقواعد السلوك الخاصة بالملعب أو المدرب.

- التعامل مع المستخدمين الآخرين وموظفي الملعب والمدربين باحترام، وتجنّب أي سلوك مسيء أو تمييزي أو مخالف للقانون.

- استخدام المرافق والمعدات للغرض المخصص لها فقط، وبذل العناية المعقولة لتجنب إتلافها.

- عدم استخدام التطبيق لأي غرض احتيالي أو غير قانوني أو تجاري غير مصرح به، بما في ذلك إعادة بيع الحجوزات دون تصريح.

قد تؤدي مخالفة هذا البند إلى تعليق حسابك أو إنهائه، وإلى تحميلك المسؤولية عن أي أضرار ناتجة، بحسب مقتضى الحال.

## ٧. الصحة والسلامة وتحمّل المخاطر

تنطوي ممارسة الأنشطة الرياضية والبدنية المحجوزة عبر التطبيق على مخاطر متأصلة للإصابة. من خلال حجزك والمشاركة في أي مباراة أو حصة تدريبية أو نشاط عبر سبورتا، فإنك تقر بلياقتك البدنية للمشاركة وتتحمل طوعًا جميع المخاطر المرتبطة بهذه المشاركة.

توصي سبورتا بشدة باستشارة طبيب قبل البدء بأي نشاط بدني جديد، خصوصًا في حال وجود حالات صحية سابقة. سبورتا ليست جهة طبية ولا تقدّم استشارات طبية.

إلى أقصى حد يسمح به القانون، لا تتحمل سبورتا المسؤولية عن أي إصابة أو مرض أو وفاة أو ضرر بالممتلكات ينتج عن المشاركة في الأنشطة المحجوزة عبر التطبيق.

## ٨. شركاء الملاعب والمدربون

الملاعب والمرافق والمدربون المدرجون على التطبيق هم أطراف مستقلة، وهم المسؤولون الوحيدون عن دقة معلوماتهم المعروضة، وحالة وسلامة مرافقهم، وجودة الخدمات والتدريب الذي يقدمونه.

تتخذ سبورتا خطوات معقولة للتحقق من معلومات الشركاء، لكنها لا تضمن دقة أو اكتمال أو موثوقية أي إعلان أو تقييم أو مراجعة. ينبغي أولاً إثارة أي خلاف بشأن جودة ملعب أو مرفق أو حصة تدريبية مع الشريك المعني، ثم تصعيده إلى دعم سبورتا للوساطة عند الحاجة.

## ٩. الملكية الفكرية

جميع المحتويات الموجودة على التطبيق، بما في ذلك اسم سبورتا وشعارها وتصميمها وبرامجها ورسومها ونصوصها، هي ملك لسبورتا أو الجهات المرخِّصة لها، ومحمية بموجب قوانين الملكية الفكرية المعمول بها. لا يجوز لك نسخ أو تعديل أو توزيع أو إنشاء أعمال مشتقة من أي جزء من التطبيق دون موافقة خطية مسبقة منا.

يبقى أي محتوى تقدّمه على التطبيق (مثل المراجعات أو الصور أو نتائج المباريات) ملكًا لك، ولكن بتقديمه فإنك تمنح سبورتا ترخيصًا عالميًا غير حصري وخاليًا من حقوق الملكية لاستخدام هذا المحتوى وعرضه وتوزيعه في سياق تشغيل التطبيق والترويج له.

## ١٠. التعويض

توافق على تعويض سبورتا ومسؤوليها وموظفيها والشركات التابعة لها وإبرائهم من أي مطالبات أو أضرار أو خسائر أو مصاريف (بما في ذلك أتعاب المحاماة المعقولة) الناشئة عن مخالفتك لهذه الشروط، أو إساءة استخدامك للتطبيق، أو انتهاكك لأي قانون معمول به أو حق لطرف ثالث.

## ١١. التعليق والإنهاء

يجوز لسبورتا تعليق أو إنهاء وصولك إلى التطبيق، بإشعار أو دونه، في حال مخالفتك لهذه الشروط، أو انخراطك في نشاط احتيالي أو غير قانوني، أو تشكيلك خطرًا على المستخدمين الآخرين أو الشركاء أو التطبيق ذاتها.

يمكنك إغلاق حسابك في أي وقت من خلال إعدادات التطبيق أو بالتواصل مع فريق الدعم لدينا. لا يؤثر الإنهاء على أي حقوق أو التزامات نشأت قبل الإنهاء، بما في ذلك التزامات الدفع المستحقة.

## ١٢. الخصوصية

يخضع استخدامك للتطبيق أيضًا لسياسة الخصوصية الخاصة بنا، والتي توضح كيفية جمعنا لبياناتك الشخصية واستخدامها ومشاركتها وحمايتها. يُرجى مراجعتها بعناية.

## ١٣. تعديلات هذه الشروط

يجوز لنا تعديل هذه الشروط من وقت لآخر لتعكس التغيرات في خدماتنا أو المتطلبات القانونية أو ممارسات العمل. سيتم إبلاغك بأي تغييرات جوهرية عبر التطبيق أو رسالة واتساب قبل سريانها بسبعة (7) أيام على الأقل. يُعد استمرارك في استخدام التطبيق بعد تاريخ السريان بمثابة قبول للشروط المعدّلة.

## ١٤. القانون الحاكم وتسوية النزاعات

تخضع هذه الشروط وتُفسَّر وفقًا لأنظمة المملكة العربية السعودية. يتم أولًا تسوية أي نزاع ينشأ عن هذه الشروط أو يتعلق بها عبر التفاوض بحسن نية بين الطرفين؛ وإذا تعذّر ذلك، يُحال النزاع إلى المحاكم المختصة في المملكة العربية السعودية.

## ١٦. تواصل معنا

إذا كانت لديك أي أسئلة بخصوص هذه الشروط، يُرجى التواصل معنا عبر:

- البريد الإلكتروني: support@sportaapp.net

- المراسلة من داخل التطبيق
""";

    // ── Privacy Policy ──────────────────────────────────────────────────────

    public const string PrivacyEn = """
## 1. Introduction

Sporta ("Sporta", "we", "us", "our") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains what information we collect through the Sporta application and website (the "Platform"), how we use and share it, and the rights you have regarding your data.

This Policy applies to all Users of the Platform and should be read together with our Terms and Conditions. By using the Platform, you consent to the collection and use of information as described in this Policy, in line with the Kingdom of Saudi Arabia's Personal Data Protection Law (PDPL) and its implementing regulations.

## 2. Information We Collect

We collect the following categories of information:

### a. Information you provide to us

- Account information: full name, mobile number, date of birth, gender, and profile photo.

- Payment information: card details or digital wallet information, processed securely through our licensed payment partners (Sporta does not store full card numbers).

- Booking details: preferred sports, skill level, match history, coach/venue preferences, and communications with venues or coaches.

- Support communications: any information you share when contacting our customer support team.

### b. Information collected automatically

- Device and usage data: IP address, device type, operating system, app version, and general usage patterns.

- Location data: with your permission, approximate or precise location to help you find nearby venues and to enable check-in features.

- Cookies and similar technologies as described in Section 7.

### c. Information from third parties

- Information from venues and coaches you book with (e.g., attendance confirmation).

- Information from social login providers if you choose to sign in using a third-party account.

- Information from payment processors necessary to confirm and reconcile transactions.

## 3. How We Use Your Information

We use your information for the following purposes:

- To create and manage your account and authenticate your identity.

- To process bookings, payments, cancellations, and refunds.

- To connect you with venues, facilities, coaches, and other players (e.g., for open matches).

- To personalize your experience, including recommending venues, coaches, or matches near you.

- To send booking confirmations, reminders, and important service notifications.

- To send marketing communications where you have opted in, and which you may opt out of at any time.

- To detect, investigate, and prevent fraud, abuse, or violations of our Terms.

- To comply with legal obligations and respond to lawful requests from public authorities.

- To analyze usage trends and improve the performance, safety, and features of the Platform.

## 4. Legal Basis for Processing

We process your personal data on the following legal grounds: performance of a contract with you (e.g., to complete a booking), your consent (e.g., for marketing or precise location), compliance with a legal obligation, and our legitimate interests in operating, securing, and improving the Platform, provided such interests are not overridden by your rights and interests.

## 5. Sharing and Disclosure of Information

We do not sell your personal data. We may share information with:

- Venues and coaches, to the extent necessary to fulfil your booking (e.g., your name and booking time).

- Payment service providers, to process transactions securely.

- Service providers who support our operations, such as cloud hosting, analytics, customer support, and SMS/WhatsApp message delivery, under confidentiality obligations.

- Other players, in the limited context of open or group matches you choose to join.

- Regulators, courts, or law enforcement authorities, where required by law or to protect the rights, safety, or property of Sporta, our Users, or the public.

- A successor entity in the event of a merger, acquisition, or sale of assets, subject to equivalent privacy protections.

## 6. Data Storage and Security

We implement administrative, technical, and physical safeguards designed to protect your personal data against unauthorized access, alteration, disclosure, or destruction, including encryption in transit, access controls, and regular security reviews.

While we take reasonable steps to protect your data, no method of transmission or storage is completely secure, and we cannot guarantee absolute security. You are responsible for keeping your account credentials confidential.

## 7. Cookies and Tracking Technologies

The Platform uses cookies, SDKs, and similar technologies to keep you signed in, remember your preferences, analyze traffic, and improve our services. You can manage cookie preferences through your device or browser settings; disabling certain cookies may limit some Platform functionality.

## 8. Your Rights

Subject to applicable law, you have the right to:

- Access the personal data we hold about you.

- Request correction of inaccurate or incomplete data.

- Request deletion of your data, subject to legal or contractual retention requirements.

- Delete your account yourself, at any time, directly from the app — see Section 14.

- Withdraw consent for marketing communications or location tracking at any time.

- Request a copy of your data in a portable format, where applicable.

- Object to certain processing activities based on our legitimate interests.

To exercise any of these rights, please contact us using the details in Section 12. We will respond within the timeframe required by applicable law.

## 9. Data Retention

We retain your personal data for as long as your account is active and for a reasonable period thereafter to comply with legal, accounting, dispute-resolution, and regulatory requirements. When data is no longer needed, we securely delete or anonymize it.

## 10. Children's Privacy

The Platform is not directed at children under 18. Where a minor participates in coaching sessions or matches booked by a parent or legal guardian, the account and consent responsibility remains with that parent or guardian, who is responsible for the minor's data and safety on the Platform.

## 11. International Data Transfers

Where your data is transferred to or processed in a country outside the Kingdom of Saudi Arabia (for example, by a cloud service provider), we ensure appropriate safeguards are in place consistent with the requirements of the Personal Data Protection Law.

## 12. Contact Us

If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact our Data Protection contact at:

- Email: support@sportaapp.net

- In-App Messaging

## 13. Changes to This Policy

We may update this Privacy Policy periodically to reflect changes in our practices or legal requirements. We will notify you of material changes through the Platform or by WhatsApp message, and we encourage you to review this Policy periodically.

## 14. Deleting Your Account

You can delete your Sporta account at any time, without contacting support: open the app and go to **Profile → Account Settings → Delete Account**. You will be asked to confirm with a verification code sent to you on WhatsApp, and the deletion is carried out immediately.

When you delete your account:

- Your personal data is erased: name, phone number, profile photo, uploaded identity and commercial documents, saved location, city and district, bank account details (IBAN, bank name, account holder), and loyalty points balance.

- Your notifications, friend connections, follows, favorite courts, and support conversations are permanently deleted.

- Your upcoming bookings and coaching sessions are cancelled. If you own a venue, its courts are removed from the app and any upcoming bookings made by other users are cancelled and refunded to their wallets.

- You can no longer sign in, and your phone number becomes available for a new registration.

- Any remaining wallet balance and any non-refundable amounts already paid are forfeited. Withdraw your balance and settle your bookings before deleting.

Records required for accounting, tax, and dispute-resolution purposes (such as past bookings and payment transactions) are retained in anonymized form that is no longer linked to your identity, for the period required by applicable law.
""";

    public const string PrivacyAr = """
## ١. مقدمة

يحترم سبورتا ("سبورتا"، "نحن") خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه المعلومات التي نجمعها من خلال تطبيق سبورتا ، وكيفية استخدامها ومشاركتها، والحقوق التي تملكها فيما يتعلق ببياناتك.

تنطبق هذه السياسة على جميع مستخدمي التطبيق، ويجب قراءتها إلى جانب الشروط والأحكام الخاصة بنا. باستخدامك للتطبيق، فإنك توافق على جمع واستخدام المعلومات على النحو الموضح في هذه السياسة، بما يتوافق مع نظام حماية البيانات الشخصية في المملكة العربية السعودية ولوائحه التنفيذية.

## ٢. المعلومات التي نجمعها

نقوم بجمع الفئات التالية من المعلومات:

### أ. المعلومات التي تقدمها لنا

- معلومات الحساب: الاسم الكامل، رقم الجوال، تاريخ الميلاد، الجنس، والصورة الشخصية.

- معلومات الدفع: تفاصيل البطاقة أو المحفظة الرقمية، والتي تتم معالجتها بأمان عبر شركاء الدفع المرخصين لدينا (لا تقوم سبورتا بتخزين أرقام البطاقات كاملة).

- تفاصيل الحجز: الرياضات المفضلة، مستوى المهارة، سجل المباريات، تفضيلات المدرب/الملعب، والمراسلات مع الملاعب أو المدربين.

- مراسلات الدعم: أي معلومات تشاركها عند التواصل مع فريق دعم العملاء لدينا.

### ب. المعلومات التي يتم جمعها تلقائيًا

- بيانات الجهاز والاستخدام: عنوان IP، نوع الجهاز، نظام التشغيل، إصدار التطبيق، وأنماط الاستخدام العامة.

- بيانات الموقع الجغرافي: بموافقتك، الموقع التقريبي أو الدقيق لمساعدتك في إيجاد الملاعب القريبة وتمكين ميزات تسجيل الحضور.

- ملفات تعريف الارتباط (الكوكيز) والتقنيات المشابهة كما هو موضح في البند 7.

### ج. المعلومات من أطراف ثالثة

- معلومات من الملاعب والمدربين الذين تحجز معهم (مثل تأكيد الحضور).

- معلومات من مزودي تسجيل الدخول عبر وسائل التواصل الاجتماعي في حال اخترت تسجيل الدخول باستخدام حساب طرف ثالث.

- معلومات من مزودي خدمات الدفع اللازمة لتأكيد المعاملات ومطابقتها.

## ٣. كيفية استخدامنا لمعلوماتك

نستخدم معلوماتك للأغراض التالية:

- إنشاء حسابك وإدارته والتحقق من هويتك.

- معالجة الحجوزات والمدفوعات وعمليات الإلغاء والاسترجاع.

- ربطك بالملاعب والمرافق والمدربين واللاعبين الآخرين (مثل المباريات المفتوحة).

- تخصيص تجربتك، بما في ذلك اقتراح الملاعب أو المدربين أو المباريات القريبة منك.

- إرسال تأكيدات الحجز والتذكيرات والإشعارات المهمة المتعلقة بالخدمة.

- إرسال الرسائل التسويقية في حال موافقتك المسبقة، والتي يمكنك إلغاء الاشتراك فيها في أي وقت.

- اكتشاف والتحقيق في أومنع الاحتيال أو إساءة الاستخدام أو مخالفة شروطنا.

- الامتثال للالتزامات القانونية والاستجابة للطلبات القانونية من الجهات الرسمية.

- تحليل اتجاهات الاستخدام وتحسين أداء التطبيق وسلامتها وميزاتها.

## ٤. الأساس القانوني للمعالجة

نعالج بياناتك الشخصية استنادًا إلى الأسس القانونية التالية: تنفيذ العقد المبرم معك (مثل إتمام الحجز)، موافقتك (مثل التسويق أو تحديد الموقع الدقيق)، الامتثال لالتزام قانوني، والمصالح المشروعة لسبورتا في تشغيل التطبيق وتأمينها وتحسينها، شريطة ألا تتجاوز هذه المصالح حقوقك ومصالحك.

## ٥. مشاركة المعلومات والإفصاح عنها

لا تقوم سبورتا ببيع بياناتك الشخصية. قد نشارك المعلومات مع:

- الملاعب والمدربين، بالقدر اللازم لإتمام حجزك (مثل اسمك ووقت الحجز).

- مزودي خدمات الدفع، لمعالجة المعاملات بأمان.

- مزودي الخدمات الذين يدعمون عملياتنا، مثل الاستضافة السحابية والتحليلات ودعم العملاء وإرسال الرسائل النصية ورسائل واتساب، وذلك بموجب التزامات سرية.

- لاعبين آخرين، في السياق المحدود للمباريات المفتوحة أو الجماعية التي تختار الانضمام إليها.

- الجهات التنظيمية أو المحاكم أو جهات إنفاذ القانون، عند الاقتضاء بموجب القانون أو لحماية حقوق أو سلامة أو ممتلكات سبورتا أو مستخدمينا أو الجمهور.

- الجهة الخلف في حال الاندماج أو الاستحواذ أو بيع الأصول، شريطة توفير حماية خصوصية عادلة.

## ٦. تخزين البيانات وأمنها

نطبّق ضمانات إدارية وتقنية ومادية مصممة لحماية بياناتك الشخصية من الوصول غير المصرح به أو التعديل أو الإفصاح أو الإتلاف، بما في ذلك التشفير أثناء النقل، وضوابط الوصول، والمراجعات الأمنية الدورية.

رغم اتخاذنا خطوات معقولة لحماية بياناتك، لا توجد طريقة نقل أو تخزين آمنة بشكل مطلق، ولا يمكننا ضمان الأمان الكامل. أنت مسؤول عن الحفاظ على سرية بيانات الدخول الخاصة بحسابك.

## ٧. ملفات تعريف الارتباط وتقنيات التتبع

تستخدم التطبيق ملفات تعريف الارتباط وحزم البرمجيات (SDKs) وتقنيات مشابهة للحفاظ على تسجيل دخولك، وتذكر تفضيلاتك، وتحليل حركة الاستخدام، وتحسين خدماتنا. يمكنك إدارة تفضيلات ملفات تعريف الارتباط من خلال إعدادات جهازك أو متصفحك؛ وقد يؤدي تعطيل بعض ملفات تعريف الارتباط إلى الحد من بعض وظائف التطبيق.

## ٨. حقوقك

وفقًا للقانون المعمول به، يحق لك:

- الوصول إلى بياناتك الشخصية التي نحتفظ بها.

- طلب تصحيح البيانات غير الدقيقة أو غير المكتملة.

- طلب حذف بياناتك، مع مراعاة متطلبات الاحتفاظ القانونية أو التعاقدية.

- حذف حسابك بنفسك في أي وقت من داخل التطبيق مباشرة — انظر البند ١٤.

- سحب موافقتك على الرسائل التسويقية أو تتبع الموقع الجغرافي في أي وقت.

- طلب نسخة من بياناتك بصيغة قابلة للنقل، حيثما ينطبق ذلك.

- الاعتراض على بعض أنشطة المعالجة المستندة إلى مصالحنا المشروعة.

لممارسة أي من هذه الحقوق، يُرجى التواصل معنا عبر البيانات الواردة في البند 12. سنرد خلال المدة التي يحددها القانون المعمول به.

## ٩. الاحتفاظ بالبيانات

نحتفظ ببياناتك الشخصية طالما كان حسابك نشطًا، ولفترة معقولة بعد ذلك للامتثال للمتطلبات القانونية والمحاسبية ومتطلبات تسوية النزاعات والمتطلبات التنظيمية. عند عدم الحاجة إلى البيانات، نقوم بحذفها أو إخفاء هويتها بشكل آمن.

## ١٠. خصوصية الأطفال

لا يستهدف التطبيق الأطفال دون سن 18 عامًا. في حال مشاركة قاصر في حصص تدريبية أو مباريات يحجزها أحد الوالدين أو ولي الأمر الشرعي، تبقى مسؤولية الحساب والموافقة على عاتق ذلك الوالد أو ولي الأمر، وهو المسؤول عن بيانات القاصر وسلامته على التطبيق.

## ١١. نقل البيانات دوليًا

في حال نقل بياناتك أو معالجتها في دولة خارج المملكة العربية السعودية (على سبيل المثال، من قِبل مزود خدمة سحابية)، فإننا نضمن وجود ضمانات مناسبة تتوافق مع متطلبات نظام حماية البيانات الشخصية.

## ١٢. تواصل معنا

إذا كانت لديك أسئلة أو استفسارات أو طلبات بخصوص سياسة الخصوصية هذه أو بياناتك الشخصية، يُرجى التواصل مع جهة الاتصال المختصة بحماية البيانات لدينا عبر:

- البريد الإلكتروني: support@sportaapp.net

- المراسلة من داخل التطبيق

## ١٣. التعديلات على هذه السياسة

قد نقوم بتحديث سياسة الخصوصية هذه بشكل دوري لتعكس التغيرات في ممارساتنا أو المتطلبات القانونية. سنقوم بإخطارك بأي تغييرات جوهرية عبر التطبيق أو رسالة واتساب، ونشجعك على مراجعة هذه السياسة بشكل دوري.

## ١٤. حذف حسابك

يمكنك حذف حسابك في سبورتا في أي وقت ودون الحاجة إلى التواصل مع الدعم: افتح التطبيق ثم **الملف الشخصي ← إعدادات الحساب ← حذف الحساب**. سيُطلب منك تأكيد العملية برمز يصلك على واتساب، ويُنفَّذ الحذف فور التأكيد.

عند حذف حسابك:

- تُمسح بياناتك الشخصية: الاسم، رقم الجوال، صورة الملف الشخصي، صور الهوية والوثائق التجارية المرفوعة، الموقع المحفوظ، المدينة والحي، بيانات الحساب البنكي (الآيبان واسم البنك واسم صاحب الحساب)، ورصيد نقاط الولاء.

- تُحذف نهائيًا إشعاراتك وصداقاتك ومتابعاتك وملاعبك المفضلة ومحادثاتك مع الدعم.

- تُلغى حجوزاتك وجلساتك التدريبية القادمة. وإن كنت ملعباً، تُزال ملاعبك من التطبيق وتُلغى حجوزات المستخدمين الآخرين القادمة فيها مع ردّ مبالغها إلى محافظهم.

- لن تتمكن من تسجيل الدخول مرة أخرى، ويتحرر رقم جوالك ليُستخدم في تسجيل حساب جديد.

- يسقط أي رصيد متبقٍ في محفظتك وأي مبالغ مدفوعة غير قابلة للاسترداد. اسحب رصيدك وسوِّ حجوزاتك قبل الحذف.

أما السجلات اللازمة للأغراض المحاسبية والضريبية وتسوية النزاعات (كالحجوزات السابقة وحركات الدفع) فيُحتفظ بها بصيغة مُبهَّمة الهوية لا ترتبط بك، وللمدة التي يفرضها النظام المعمول به.
""";

    // ── Refund Policy ───────────────────────────────────────────────────────

    public const string RefundEn = """
## 1. Overview

This Refund Policy explains how cancellations, rescheduling, and refunds are handled for bookings made through the Sporta application and website (the "Platform"), including court/field bookings, coaching sessions, and match participation fees. This Policy forms part of, and should be read together with, our Terms and Conditions.

Because Sporta connects Users with independent venues and coaches ("Partners"), specific cancellation windows may vary slightly by Partner; where a Partner's policy is stricter or more generous than the general rule below, the policy shown at the time of booking will apply and will always be clearly displayed before you confirm payment.

## 2. User-Initiated Cancellations — Court and Field Bookings

Unless a different window is shown at checkout for a specific venue, the following general cancellation tiers apply to court and field bookings:

- More than 24 hours before the booking start time: full refund of the amount paid, minus any non-refundable service fee (see Section 8).
- Between 6 and 24 hours before the booking start time: 50% refund of the amount paid.
- Less than 6 hours before the booking start time, or after the booking start time: no refund.

Refunds under this section are automatically calculated by the Platform based on the cancellation timestamp and will be reflected in your account after processing.

## 3. Coach and Training Session Cancellations

Bookings with individual coaches may carry cancellation terms set by the coach, which will be displayed at the time of booking. In the absence of a coach-specific policy, the following general rule applies:

- More than 24 hours before the session: full refund.
- Between 12 and 24 hours before the session: 50% refund.
- Less than 12 hours before the session: no refund, unless the coach agrees to reschedule at their discretion.

## 4. No-Show Policy

If you fail to attend a confirmed booking without cancelling in advance ("no-show"), no refund will be issued, and this may be recorded on your account. Repeated no-shows may result in temporary restrictions on your ability to make future bookings, in accordance with Section 6 of our Terms and Conditions.

## 5. Cancellations by Sporta, a Venue, or a Coach

If a booking is cancelled by Sporta, a venue, or a coach — for example due to facility maintenance, unavailability, or a coach being unable to attend — you will receive a full refund of the amount paid, including any service fee, or you may choose to reschedule at no additional cost, where available.

Where reasonably possible, we will notify you of such cancellations as early as possible and will assist you in finding an alternative venue, time slot, or coach.

## 6. Weather and Force Majeure

For outdoor courts and fields, bookings cancelled due to severe weather conditions confirmed by the venue (e.g., heavy rain, storms) that make the facility unsafe or unusable are eligible for a full refund or free rescheduling, regardless of the cancellation timing rules in Section 2.

Sporta and its Partners are not liable for cancellations or service interruptions caused by events beyond reasonable control, including but not limited to natural disasters, government restrictions, power outages, or public health emergencies; in such cases, reasonable efforts will be made to offer a refund or rescheduling option.

## 7. Refund Method and Processing Time

Eligible refunds will be issued to the original payment method used for the booking, or, at your option and where supported, credited to your Sporta wallet for faster processing on future bookings.

- Sporta wallet credits are typically applied instantly.
- Refunds to cards or digital wallets typically take 5–14 business days to appear, depending on your bank or payment provider.

## 8. Non-Refundable Fees

Certain amounts are non-refundable except where a booking is cancelled by Sporta, a venue, or a coach as described in Section 5, or where required by applicable law:

- The Sporta service/booking fee shown separately at checkout.
- Payment processing fees charged by third-party payment providers, where applicable.
- Amounts for add-on services already consumed at the time of cancellation (e.g., equipment rental already used).

## 9. Group and Split-Payment Bookings

For bookings shared among multiple participants, each participant's payment is treated individually for refund purposes based on their own cancellation timing. If the organizer cancels the entire booking, the applicable refund tier under Section 2 applies to each participant's paid share. Sporta is not responsible for redistributing funds among participants outside the Platform's payment system.

## 10. How to Request a Refund

Most cancellations and refunds can be processed directly through the "My Bookings" section of the app. If you experience an issue not covered by the automatic refund calculation (for example, a dispute about facility condition or coach conduct), you may submit a refund request to our support team within 48 hours of the booking, including relevant details and, where possible, supporting evidence (photos, messages).

Our team will review manual refund requests and respond within five (5) business days.

## 11. Contact Us

For questions about this Refund Policy, please contact us at:

- Email: support@sportaapp.net
- In-App Messaging
""";

    public const string RefundAr = """
## ١. نظرة عامة

توضح سياسة الاسترجاع هذه كيفية التعامل مع عمليات الإلغاء وإعادة الجدولة والاسترجاع للحجوزات التي تتم عبر تطبيق وموقع سبورتا ("التطبيق")، بما في ذلك حجوزات الملاعب، والحصص التدريبية، ورسوم المشاركة في المباريات. تُعد هذه السياسة جزءًا من الشروط والأحكام الخاصة بنا ويجب قراءتها معها.

نظرًا لأن سبورتا تربط المستخدمين بملاعب ومدربين مستقلين ("الشركاء")، قد تختلف مُهل الإلغاء المحددة قليلًا بحسب كل شريك؛ وفي حال كانت سياسة أحد الشركاء أكثر صرامة أو مرونة من القاعدة العامة أدناه، تُطبَّق السياسة المعروضة وقت الحجز، والتي ستُعرض بوضوح دائمًا قبل تأكيد الدفع.

## ٢. الإلغاء من قِبل المستخدم — حجوزات الملاعب

ما لم تُعرض مهلة مختلفة عند إتمام الحجز لملعب معين، تُطبَّق فئات الإلغاء العامة التالية على حجوزات الملاعب:

- قبل أكثر من 24 ساعة من موعد بدء الحجز: استرجاع كامل للمبلغ المدفوع، باستثناء أي رسوم خدمة غير قابلة للاسترجاع (انظر البند 8).
- بين 6 و24 ساعة قبل موعد بدء الحجز: استرجاع 50٪ من المبلغ المدفوع.
- أقل من 6 ساعات قبل موعد بدء الحجز، أو بعد بدء الحجز: لا يوجد استرجاع.

يتم احتساب الاسترجاع بموجب هذا البند تلقائيًا من قِبل التطبيق استنادًا إلى وقت الإلغاء، وسينعكس في حسابك بعد معالجته.

## ٣. إلغاء حصص التدريب مع المدربين

قد تحمل الحجوزات مع المدربين الأفراد شروط إلغاء يحددها المدرب، وستُعرض عند الحجز. في حال عدم وجود سياسة خاصة بالمدرب، تُطبَّق القاعدة العامة التالية:

- قبل أكثر من 24 ساعة من الحصة: استرجاع كامل.
- بين 12 و24 ساعة قبل الحصة: استرجاع 50٪.
- أقل من 12 ساعة قبل الحصة: لا يوجد استرجاع، ما لم يوافق المدرب على إعادة الجدولة وفق تقديره الخاص.

## ٤. سياسة عدم الحضور

في حال عدم حضورك لحجز مؤكد دون إلغائه مسبقًا ("عدم الحضور")، لن يتم إصدار أي استرجاع، وقد يُسجَّل ذلك على حسابك. قد يؤدي تكرار عدم الحضور إلى فرض قيود مؤقتة على قدرتك على إجراء حجوزات مستقبلية، وذلك وفقًا للبند 6 من الشروط والأحكام الخاصة بنا.

## ٥. الإلغاء من قِبل سبورتا أو الملعب أو المدرب

في حال إلغاء الحجز من قِبل سبورتا أو الملعب أو المدرب — على سبيل المثال بسبب أعمال صيانة أو عدم توفر المرفق أو عدم تمكن المدرب من الحضور — ستحصل على استرجاع كامل للمبلغ المدفوع، بما في ذلك أي رسوم خدمة، أو يمكنك اختيار إعادة الجدولة دون أي تكلفة إضافية، حيثما كان ذلك متاحًا.

سنقوم، حيثما أمكن ذلك بشكل معقول، بإخطارك بهذا الإلغاء في أقرب وقت ممكن، وسنساعدك في إيجاد ملعب أو موعد أو مدرب بديل.

## ٦. الطقس والقوة القاهرة

بالنسبة للملاعب الخارجية، فإن الحجوزات التي تُلغى بسبب ظروف جوية شديدة يؤكدها الملعب (مثل الأمطار الغزيرة أو العواصف) والتي تجعل المرفق غير آمن أو غير قابل للاستخدام، تكون مؤهلة لاسترجاع كامل أو إعادة جدولة مجانية، بغض النظر عن قواعد توقيت الإلغاء الواردة في البند 2.

لا تتحمل سبورتا وشركاؤها المسؤولية عن الإلغاءات أو انقطاعات الخدمة الناتجة عن أحداث خارجة عن السيطرة المعقولة، بما في ذلك على سبيل المثال لا الحصر الكوارث الطبيعية، أو القيود الحكومية، أو انقطاع الكهرباء، أو حالات الطوارئ الصحية العامة؛ وفي هذه الحالات، سنبذل جهودًا معقولة لتقديم خيار الاسترجاع أو إعادة الجدولة.

## ٧. طريقة الاسترجاع ومدة المعالجة

سيتم إصدار المبالغ المستردة المؤهلة إلى وسيلة الدفع الأصلية المستخدمة في الحجز، أو، بناءً على اختيارك وحيثما كان ذلك مدعومًا، إضافتها كرصيد في محفظة سبورتا لمعالجة أسرع في الحجوزات المستقبلية.

- عادةً ما يتم إضافة أرصدة محفظة سبورتا فورًا.
- عادةً ما تستغرق المبالغ المستردة إلى البطاقات أو المحافظ الرقمية من 5 إلى 14 يوم عمل لتظهر، بحسب البنك أو مزود خدمة الدفع.

## ٨. الرسوم غير القابلة للاسترجاع

تُعد بعض المبالغ غير قابلة للاسترجاع، إلا في حال إلغاء الحجز من قِبل سبورتا أو الملعب أو المدرب على النحو الموضح في البند 5، أو عند الاقتضاء بموجب القانون المعمول به:

- رسوم الخدمة/الحجز الخاصة بسبورتا الموضحة بشكل منفصل عند إتمام الحجز.
- رسوم معالجة الدفع التي يفرضها مزودو خدمات الدفع الخارجيون، حيثما ينطبق ذلك.
- مبالغ الخدمات الإضافية التي تم استهلاكها بالفعل وقت الإلغاء (مثل تأجير معدات تم استخدامها بالفعل).

## ٩. الحجوزات الجماعية والمقسّمة الدفع

بالنسبة للحجوزات المشتركة بين عدة مشاركين، تُعامل دفعة كل مشارك بشكل منفصل لأغراض الاسترجاع استنادًا إلى توقيت إلغائه الخاص. في حال إلغاء المنظّم للحجز بالكامل، تُطبَّق فئة الاسترجاع المناسبة بموجب البند 2 على حصة كل مشارك المدفوعة. لا تتحمل سبورتا مسؤولية إعادة توزيع الأموال بين المشاركين خارج نظام الدفع الخاص بالتطبيق.

## ١٠. كيفية طلب الاسترجاع

يمكن معالجة معظم عمليات الإلغاء والاسترجاع مباشرة من خلال قسم "حجوزاتي" في التطبيق. إذا واجهت مشكلة لا يغطيها الاحتساب التلقائي للاسترجاع (مثل خلاف حول حالة المرفق أو سلوك المدرب)، يمكنك تقديم طلب استرجاع إلى فريق الدعم لدينا خلال 48 ساعة من موعد الحجز، مع تضمين التفاصيل ذات الصلة، وحيثما أمكن، أي أدلة داعمة (صور، رسائل).

سيقوم فريقنا بمراجعة طلبات الاسترجاع اليدوية والرد خلال خمسة (5) أيام عمل.

## ١١. تواصل معنا

للأسئلة المتعلقة بسياسة الاسترجاع هذه، يُرجى التواصل معنا عبر:

- البريد الإلكتروني: support@sportaapp.net
- المراسلة من داخل التطبيق
""";
}
