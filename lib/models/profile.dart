class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  /// User ID of the profile
  final String id;

  /// Username of the profile
  final String username;

  /// Date and time when the profile was created
  final DateTime createdAt;

  Map<String, dynamic> toMap() {  //toMap ->   অবজেক্টের ডাটাকে Map/JSON এ রূপান্তর করে যাতে ডাটাবেসে সেভ করা যায়।
    return {
      'id': id,  // ইউজারের ইউনিক আইডেন্টিফায়ার (Primary Key), যা দিয়ে ডাটাবেস তাকে চেনে।
      'username': username,  //অ্যাপে প্রদর্শিত ইউজারের নাম। এটি চ্যাট লিস্ট এবং প্রোফাইলে দেখানো হয়।
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Profile.fromMap(Map<String, dynamic> map)  //  fromMap -> ডাটাবেস থেকে আসা কাঁচা (Raw) তথ্যকে Flutter-এর ব্যবহারযোগ্য Profile অবজেক্টে পরিণত করে।
      : id = map['id'],   // map['id']  ->    ডাটাবেসের টেবিল থেকে 'id' কলামের ভ্যালুটিকে খুঁজে বের করে।
        username = map['username'],
        createdAt = DateTime.parse(map['created_at']);   //  ডাটাবেসের টেক্সট ফরম্যাটের সময়কে মানুষের পড়ার যোগ্য DateTime ফরম্যাটে কনভার্ট করে।

  Profile copyWith({  //  বর্তমান প্রোফাইলের তথ্য ঠিক রেখে কোনো নির্দিষ্ট অংশ (যেমন: ইউজারনেম) আপডেট করতে সাহায্য করে।
    String? id,
    String? name,
    DateTime? createdAt,  //ইউজার ঠিক কবে এবং কখন একাউন্ট খুলেছেন তার নির্ভুল সময় ধরে রাখে।
  }) {
    return Profile(
      id: id ?? this.id,  //  ?? -> যদি নতুন তথ্য না দেওয়া হয়, তবে আগের পুরনো তথ্যটিকেই ব্যবহার করে।
      username: name ?? username,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


/*

এই Profile Model ফাইলটি আপনার অ্যাপে ব্যবহারকারীদের পরিচয় নিশ্চিত করে। এর প্রধান কাজগুলো হলো:
১. Data Structuring: ডাটাবেসের টেবিল (Row/Column) থেকে ডাটা এনে সেটিকে Profile.username বা Profile.id হিসেবে সাজিয়ে দেয়, যাতে কোড লেখা সহজ হয়।
২. Consistency: পুরো অ্যাপে ইউজারের তথ্য যাতে একই ফরম্যাটে থাকে তা নিশ্চিত করে। এর ফলে ভুল ডাটা ইনপুট হওয়ার সম্ভাবনা কমে যায়।
৩. Real-time Support: fromMap ব্যবহারের ফলে যখনই ডাটাবেসে কোনো ইউজারের নাম পরিবর্তন হয়, অ্যাপটি দ্রুত সেই নতুন ম্যাপ থেকে অবজেক্ট তৈরি করে স্ক্রিনে আপডেট দেখাতে পারে।
৪. Timeline: ইউজার কতদিন ধরে অ্যাপটি ব্যবহার করছেন তা createdAt এর মাধ্যমে ট্র্যাক করা যায়।

 */