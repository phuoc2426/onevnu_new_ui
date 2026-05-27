import 'dart:math' as math;
import 'local_embedding_model.dart';
import 'simple_tokenizer.dart';

class OnnxEmbeddingModel extends LocalEmbeddingModel {
  OnnxEmbeddingModel({
    required this.modelAssetPath,
    required this.vocabAssetPath,
  });

  final String modelAssetPath;
  final String vocabAssetPath;

  // ignore: unused_field
  late final SimpleTokenizer _tokenizer;
  bool _loaded = false;

  @override
  Future<void> load() async {
    if (_loaded) return;
    _tokenizer = await SimpleTokenizer.fromAsset(vocabAssetPath);
    _loaded = true;
  }

  @override
  Future<List<double>> embed(String text) async {
    await load();
    
    // Structure is set up for ONNX runtime integration.
    // To use ONNX runtime:
    // 1. Add `flutter_onnxruntime` to pubspec.yaml
    // 2. Import `package:flutter_onnxruntime/flutter_onnxruntime.dart`
    // 3. Initialize OrtSession: `_session = await OrtSession.fromAsset(modelAssetPath);`
    // 4. Run session:
    //    final tokenized = _tokenizer.encode(_prefixForE5(text));
    //    final outputs = await _session.run({
    //      'input_ids': tokenized.inputIds,
    //      'attention_mask': tokenized.attentionMask,
    //      'token_type_ids': tokenized.tokenTypeIds,
    //    });
    //    final lastHiddenState = outputs['last_hidden_state'];
    //    return meanPooling(tokenEmbeddings: lastHiddenState, attentionMask: tokenized.attentionMask);

    // Default fully offline Dart-native fallback semantic embedding
    return _conceptEmbedding(text);
  }

  // ignore: unused_element
  String _prefixForE5(String text) {
    return 'passage: $text';
  }

  List<double> meanPooling({
    required List<List<double>> tokenEmbeddings,
    required List<int> attentionMask,
  }) {
    if (tokenEmbeddings.isEmpty) return [];

    final dim = tokenEmbeddings.first.length;
    final pooled = List<double>.filled(dim, 0);
    double count = 0;

    for (var i = 0; i < tokenEmbeddings.length; i++) {
      if (attentionMask[i] == 0) continue;

      for (var j = 0; j < dim; j++) {
        pooled[j] += tokenEmbeddings[i][j];
      }

      count++;
    }

    if (count == 0) return pooled;

    for (var j = 0; j < dim; j++) {
      pooled[j] /= count;
    }

    return _normalize(pooled);
  }

  List<double> _normalize(List<double> vector) {
    final norm = math.sqrt(
      vector.fold<double>(0.0, (sum, value) => sum + value * value),
    );

    if (norm == 0) return vector;

    return vector.map((e) => e / norm).toList(growable: false);
  }

  // --- Offline Fallback Concept Vector Semantic Embedding ---
  static const List<List<String>> _concepts = [
    // 0. Programming & Software Development
    ['lap trinh', 'coding', 'oop', 'java', 'python', 'c++', 'flutter', 'dart', 'mobile', 'web', 'phan mem', 'kiem thu', 'software', 'source code', 'phat trien phan mem', 'lap trinh vien', 'huong doi tuong'],
    // 1. Databases & Information Systems
    ['co so du lieu', 'database', 'sql', 'nosql', 'query', 'truy van', 'phuc hoi', 'sao luu', 'mysql', 'oracle', 'mongodb', 'he thong thong tin', 'du lieu', 'he quan tri'],
    // 2. Networks, OS & Cyber Security
    ['mang may tinh', 'network', 'an toan thong tin', 'bao mat', 'security', 'cryptography', 'mat ma', 'he dieu hanh', 'linux', 'unix', 'windows', 'cloud', 'aws', 'ha tang mang'],
    // 3. Artificial Intelligence & Data Science
    ['tri tue nhan tao', 'artificial intelligence', 'ai', 'machine learning', 'hoc may', 'deep learning', 'neuron', 'xuly anh', 'computer vision', 'nlp', 'khai pha du lieu', 'data mining', 'big data'],
    // 4. Mathematics & Logic
    ['toan', 'algebra', 'calculus', 'giai tich', 'dai so', 'xac suat', 'thong ke', 'logic', 'roi rac', 'toi uu', 'hinh hoc', 'ma tran', 'vector'],
    // 5. English & Languages
    ['tieng anh', 'english', 'ielts', 'toeic', 'giao tiep', 'ngu phap', 'nghe noi', 'doc viet', 'pronunciation', 'ngoai ngu'],
    // 6. Business, Economics & Management
    ['kinh doanh', 'business', 'quan tri', 'marketing', 'tai chinh', 'ke toan', 'ngan hang', 'khoi nghiep', 'kinh te', 'doanh nghiep', 'nhan su', 'marketing', 'pr'],
    // 7. Law, Governance & Ethics
    ['luat', 'phap luat', 'phap ly', 'hien phap', 'hinh su', 'dan su', 'to tung', 'tranh tung', 'luat khoa', 'quy dinh', 'dieu khoan', 'nghi dinh', 'nghi quyet', 'dao duc'],
    // 8. Education & Pedagogy
    ['giao duc', 'pedagogy', 'su pham', 'giang day', 'day hoc', 'tam ly hoc', 'phuong phap giang day', 'dao tao', 'hoc tap'],
    // 9. UI/UX Design & Multimedia
    ['thiet ke', 'design', 'giao dien', 'graphics', 'do hoa', 'ui', 'ux', 'figma', 'photoshop', 'my thuat', 'mau sac', 'tuong tac', 'trai nghiem nguoi dung'],
    // 10. Research, Thesis & Internship
    ['do an', 'khoa luan', 'luan van', 'thuc tap', 'chuyen de', 'bao cao', 'nghien cuu khoa hoc', 'project', 'capstone'],
    // 11. Politics, Philosophy & History
    ['triet hoc', 'mac lenin', 'mac le', 'chinh tri', 'dang cong san', 'tu tuong ho chi minh', 'lich su dang', 'duong loi', 'chu nghia'],
    // 12. Physics, Electronics & Hardware
    ['vat ly', 'physics', 'dien tu', 'vi dieu khien', 'iot', 'nhung', 'hardware', 'cam bien', 'circuit', 'mach dien', 'phan cung'],
    // 13. Sports, Arts & Physical Education
    ['the duc', 'the thao', 'bong da', 'bong ro', 'cau long', 'am nhac', 'hoi hoa', 'nghe thuat', 'the chat']
  ];

  static String _removeDiacritics(String text) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = text.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  List<double> _conceptEmbedding(String text) {
    final cleanText = _removeDiacritics(text);
    final size = _concepts.length;
    final vector = List<double>.filled(size, 0.0);

    for (var i = 0; i < size; i++) {
      var score = 0.0;
      for (final keyword in _concepts[i]) {
        if (cleanText.contains(keyword)) {
          // Give higher score for exact/longer word matches
          score += keyword.split(' ').length.toDouble() * 1.5;
        }
      }
      vector[i] = score;
    }

    // Add uniform tiny base activation to avoid zero vectors
    for (var i = 0; i < size; i++) {
      vector[i] += 0.05;
    }

    return _normalize(vector);
  }
}
