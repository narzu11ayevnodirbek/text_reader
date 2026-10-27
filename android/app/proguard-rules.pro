# google_mlkit_text_recognition boshqa yozuvlar (xitoy, devanagari, yapon, koreys) uchun klasslarga havola qiladi,
# lekin ilova faqat lotin yozuvini o'qiydi va bu modullar qo'shilmagan. R8 ularni topolmay release build'ni to'xtatmasligi uchun.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
