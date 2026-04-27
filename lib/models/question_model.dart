class Question {
  final String question;
  final List<String> options;
  final String category;
  final String type; // 'high' or 'low'

  const Question({
    required this.question,
    required this.options,
    required this.category,
    required this.type,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: [
        json['option1'] as String,
        json['option2'] as String,
        json['option3'] as String,
        json['option4'] as String,
        json['option5'] as String,
      ],
      category: json['category'] as String,
      type: json['type'] as String,
    );
  }

  int scoreForOption(int optionIndex) {
    if (type == 'high') {
      const scores = [2, 4, 6, 8, 10];
      return scores[optionIndex];
    } else {
      const scores = [1, 2, 3, 4, 5];
      return scores[optionIndex];
    }
  }
}
