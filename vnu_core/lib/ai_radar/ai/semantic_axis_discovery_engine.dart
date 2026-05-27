import '../embedding/local_embedding_model.dart';
import '../models/academic_course.dart';
import '../models/radar_axis_profile.dart';
import 'vector_math.dart';

class AcademicDomain {
  const AcademicDomain({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.description,
    required this.axes,
  });

  final String id;
  final String nameVi;
  final String nameEn;
  final String description;
  final List<RadarAxis> axes;
}

class SemanticAxisDiscoveryEngine {
  SemanticAxisDiscoveryEngine({
    required this.embeddingModel,
  });

  final LocalEmbeddingModel embeddingModel;

  Future<RadarAxisProfile> discover({
    required String cacheKey,
    required String school,
    required String major,
    required List<AcademicCourse> courses,
  }) async {
    // 1. Construct contextual string to classify student's study domain
    final courseNames = courses.map((e) => e.name).take(15).join(' ');
    final contextText = 'school: $school major: $major courses: $courseNames';

    // 2. Classify major/domain using offline concept semantic matching
    final contextVector = await embeddingModel.embed(contextText);

    double bestScore = -1.0;
    AcademicDomain selectedDomain = _fallbackDomain;

    for (final domain in _predefinedDomains) {
      final domainVector = await embeddingModel.embed(domain.description);
      final similarity = VectorMath.cosine(contextVector, domainVector);
      if (similarity > bestScore) {
        bestScore = similarity;
        selectedDomain = domain;
      }
    }

    // Set fallback if similarity score is extremely low
    if (bestScore < 0.2) {
      selectedDomain = _fallbackDomain;
    }

    final reasonVi = 'AI local phân tích và suy luận từ tên trường "$school", ngành/khoa "$major" cùng danh sách học phần thực tế. '
        'Lĩnh vực đào tạo phù hợp nhất được xác định là "${selectedDomain.nameVi}" (Độ tin cậy: ${(bestScore * 100).round()}%).';

    return RadarAxisProfile(
      cacheKey: cacheKey,
      school: school,
      major: major,
      inferredDomain: selectedDomain.nameVi,
      inferredSpecificMajor: major,
      domainConfidence: bestScore.clamp(0.0, 1.0),
      reasonVi: reasonVi,
      axes: selectedDomain.axes,
    );
  }

  static final List<AcademicDomain> _predefinedDomains = [
    // 1. IT & Computer Science
    AcademicDomain(
      id: 'it',
      nameVi: 'Công nghệ Thông tin & Khoa học Máy tính',
      nameEn: 'Information Technology & Computer Science',
      description: 'công nghệ thông tin khoa học máy tính lập trình phần mềm cơ sở dữ liệu hệ thống mạng an toàn thông tin trí tuệ nhân tạo oop web mobile coding sql network artificial intelligence',
      axes: [
        RadarAxis(
          code: 'PRG',
          nameVi: 'Phát triển Phần mềm',
          nameEn: 'Software Development',
          sectorRoleVi: 'Năng lực lập trình, thiết kế cấu trúc mã nguồn và kiểm thử phần mềm.',
          axisImportance: 0.95,
          axisDefinitionVi: 'Khả năng viết mã, ứng dụng nguyên lý hướng đối tượng, phát triển ứng dụng web, di động.',
          expectedEvidenceVi: 'Yêu cầu các học phần lập trình cơ bản (C/C++), lập trình hướng đối tượng (OOP), lập trình Web/Mobile, kiểm thử phần mềm.',
          seedText: 'lập trình coding oop java python c++ web mobile thiết kế phần mềm software testing',
        ),
        RadarAxis(
          code: 'DAT',
          nameVi: 'Cơ sở Dữ liệu & Hệ thống',
          nameEn: 'Databases & Information Systems',
          sectorRoleVi: 'Thiết kế, xây dựng và quản trị hệ thống dữ liệu doanh nghiệp.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Thiết kế lược đồ thực thể quan hệ, truy vấn dữ liệu SQL/NoSQL tối ưu, giao dịch dữ liệu.',
          expectedEvidenceVi: 'Yêu cầu các học phần cơ sở dữ liệu, hệ quản trị cơ sở dữ liệu, SQL, NoSQL.',
          seedText: 'cơ sở dữ liệu database sql nosql mysql oracle mongodb truy vấn tối ưu cơ sở dữ liệu',
        ),
        RadarAxis(
          code: 'NET',
          nameVi: 'Mạng & An ninh mạng',
          nameEn: 'Networking & Cyber Security',
          sectorRoleVi: 'Xây dựng hạ tầng truyền thông mạng và bảo vệ thông tin trước các lỗ hổng.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Kiến thức về các giao thức mạng, cấu trúc phần cứng mạng, kỹ thuật bảo mật, mã hóa mật mã học.',
          expectedEvidenceVi: 'Yêu cầu các học phần mạng máy tính, an toàn thông tin, bảo mật mạng, quản trị mạng, mật mã học.',
          seedText: 'mạng máy tính network an toàn thông tin bảo mật mật mã học cryptography firewall bảo mật hệ thống',
        ),
        RadarAxis(
          code: 'DAI',
          nameVi: 'Dữ liệu lớn & AI',
          nameEn: 'Data Science & Artificial Intelligence',
          sectorRoleVi: 'Khai thác dữ liệu lớn và thiết kế thuật toán học máy thông minh.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Phân tích dữ liệu thống kê, triển khai thuật toán Machine Learning/Deep Learning, thị giác máy tính.',
          expectedEvidenceVi: 'Yêu cầu các học phần trí tuệ nhân tạo (AI), học máy (Machine Learning), khai phá dữ liệu lớn (Big Data).',
          seedText: 'trí tuệ nhân tạo ai học máy machine learning deep learning data mining khai phá dữ liệu lớn big data',
        ),
        RadarAxis(
          code: 'UIX',
          nameVi: 'Thiết kế Giao diện UI/UX',
          nameEn: 'UI/UX Design',
          sectorRoleVi: 'Đảm bảo tính thẩm mỹ, trực quan và tối ưu hóa trải nghiệm người dùng cuối.',
          axisImportance: 0.75,
          axisDefinitionVi: 'Thiết kế wireframe, prototype tương tác, nghiên cứu thói quen người dùng trên ứng dụng.',
          expectedEvidenceVi: 'Yêu cầu các học phần tương tác người máy, thiết kế đồ họa, thiết kế UI/UX.',
          seedText: 'thiết kế giao diện ui ux figma đồ họa tương tác người máy photoshop frontend',
        ),
        RadarAxis(
          code: 'LOG',
          nameVi: 'Toán học & Tư duy thuật toán',
          nameEn: 'Algorithms & Mathematics',
          sectorRoleVi: 'Nền tảng logic lý thuyết cho việc tối ưu hiệu năng thuật toán.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Khả năng lập luận logic rời rạc, tính toán ma trận tuyến tính, giải thuật tìm kiếm tối ưu.',
          expectedEvidenceVi: 'Yêu cầu các học phần toán rời rạc, đại số tuyến tính, giải thuật, cấu trúc dữ liệu và giải thuật.',
          seedText: 'toán rời rạc cấu trúc dữ liệu giải thuật thuật toán đại số tuyến tính logic xác suất thống kê',
        ),
        RadarAxis(
          code: 'SYS',
          nameVi: 'Kiến trúc & Hệ điều hành',
          nameEn: 'System Architecture & OS',
          sectorRoleVi: 'Hiểu biết về phần cứng, kiến trúc máy tính và hệ điều hành điều phối tài nguyên.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Khả năng lập trình hệ thống, quản lý luồng/tiến trình, quản lý bộ nhớ và tối ưu phần cứng.',
          expectedEvidenceVi: 'Yêu cầu các học phần kiến trúc máy tính, hệ điều hành, lập trình hệ thống, vi xử lý.',
          seedText: 'hệ điều hành operating system kiến trúc máy tính computer architecture vi xử lý assembler luồng bộ nhớ phần cứng',
        ),
      ],
    ),

    // 2. Law & Legal Studies
    AcademicDomain(
      id: 'law',
      nameVi: 'Luật & Pháp lý',
      nameEn: 'Law & Jurisprudence',
      description: 'luật pháp lý hiến pháp tòa án tranh tụng tố tụng hình sự dân sự đạo đức luật hành chính tranh biện tư pháp lý luận nhà nước quy phạm pháp luật văn bản pháp quy',
      axes: [
        RadarAxis(
          code: 'LGR',
          nameVi: 'Lập luận Pháp lý',
          nameEn: 'Legal Reasoning',
          sectorRoleVi: 'Cốt lõi tư duy pháp luật trong phân tích quy phạm.',
          axisImportance: 0.95,
          axisDefinitionVi: 'Năng lực đọc hiểu và áp dụng logic pháp lý vào việc giải thích luật.',
          expectedEvidenceVi: 'Yêu cầu các học phần lý luận nhà nước và pháp luật, luật hiến pháp.',
          seedText: 'lý luận nhà nước hiến pháp lập luận pháp lý luật học lý thuyết luật',
        ),
        RadarAxis(
          code: 'CASE',
          nameVi: 'Giải quyết Vụ việc',
          nameEn: 'Case Analysis',
          sectorRoleVi: 'Năng lực thực hành giải quyết tranh chấp pháp lý thực tế.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Kỹ năng định tội danh, phân tích chứng cứ và trách nhiệm pháp lý trong các tranh chấp.',
          expectedEvidenceVi: 'Yêu cầu các học phần luật dân sự, luật hình sự, luật hành chính.',
          seedText: 'luật hình sự luật dân sự luật hành chính tranh chấp giải quyết vụ việc án dân sự vụ án hình sự',
        ),
        RadarAxis(
          code: 'CODE',
          nameVi: 'Hệ thống Văn bản quy phạm',
          nameEn: 'Statutory Systems & Procedure',
          sectorRoleVi: 'Hệ thống hóa và sử dụng chính xác các văn bản quy phạm.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Nắm vững quy trình tố tụng dân sự, hình sự và thứ bậc hiệu lực các văn bản pháp quy.',
          expectedEvidenceVi: 'Yêu cầu các học phần luật tố tụng dân sự, luật tố tụng hình sự, công pháp quốc tế.',
          seedText: 'tố tụng tố tụng dân sự tố tụng hình sự công pháp tư pháp văn bản luật luật hành chính',
        ),
        RadarAxis(
          code: 'ARG',
          nameVi: 'Tranh biện & Bào chữa',
          nameEn: 'Advocacy & Mooting',
          sectorRoleVi: 'Kỹ năng bảo vệ lợi ích hợp pháp của khách hàng trước tòa án.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Kỹ năng nói trước công chúng, hùng biện pháp lý, đặt câu hỏi tranh tụng sắc bén.',
          expectedEvidenceVi: 'Yêu cầu các học phần kỹ năng tranh tụng, thực hành tòa giả định, kỹ năng bổ trợ tư pháp.',
          seedText: 'tranh tụng bào chữa tòa giả định tranh biện hùng biện luật sư phiên tòa',
        ),
        RadarAxis(
          code: 'ETH',
          nameVi: 'Đạo đức Nghề Luật',
          nameEn: 'Legal Ethics & Professionalism',
          sectorRoleVi: 'Kim chỉ nam cho tính liêm chính và công lý của người hành nghề.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Trách nhiệm tôn trọng sự thật khách quan, bảo mật thông tin và tránh xung đột lợi ích.',
          expectedEvidenceVi: 'Yêu cầu học phần đạo đức nghề luật, lịch sử nhà nước và pháp luật.',
          seedText: 'đạo đức nghề luật công lý liêm chính quy tắc hành nghề quy tắc đạo đức nghề nghiệp',
        ),
        RadarAxis(
          code: 'RES',
          nameVi: 'Nghiên cứu & Soạn thảo pháp lý',
          nameEn: 'Legal Research & Drafting',
          sectorRoleVi: 'Kỹ năng tìm kiếm tài liệu pháp luật và soạn thảo văn bản pháp lý chuẩn mực.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Khả năng tra cứu văn bản pháp quy, soạn thảo hợp đồng thương mại, đơn từ, văn bản hành chính pháp lý.',
          expectedEvidenceVi: 'Yêu cầu các học phần kỹ năng soạn thảo văn bản pháp lý, phương pháp nghiên cứu luật học.',
          seedText: 'soạn thảo văn bản hợp đồng đơn từ nghiên cứu pháp luật tài liệu pháp lý kỹ năng viết luật',
        ),
        RadarAxis(
          code: 'INT',
          nameVi: 'Tư pháp & Luật quốc tế',
          nameEn: 'International Law',
          sectorRoleVi: 'Hiểu biết và áp dụng các công ước, luật quốc tế trong bối cảnh toàn cầu.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Năng lực phân tích công pháp quốc tế, tư pháp quốc tế, luật thương mại quốc tế.',
          expectedEvidenceVi: 'Yêu cầu các học phần công pháp quốc tế, tư pháp quốc tế, luật thương mại quốc tế.',
          seedText: 'luật quốc tế công pháp quốc tế tư pháp quốc tế thương mại quốc tế công ước hiệp định',
        ),
      ],
    ),

    // 3. Education & Pedagogy
    AcademicDomain(
      id: 'education',
      nameVi: 'Giáo dục & Sư phạm',
      nameEn: 'Education & Pedagogy',
      description: 'giáo dục sư phạm dạy học giảng dạy học sinh bài giảng giáo án tâm lý lứa tuổi khảo thí chủ nhiệm kỹ năng sư phạm giáo dục học',
      axes: [
        RadarAxis(
          code: 'PED',
          nameVi: 'Phương pháp Giảng dạy',
          nameEn: 'Teaching Pedagogy',
          sectorRoleVi: 'Năng lực tổ chức lớp học dạy học tích cực.',
          axisImportance: 0.95,
          axisDefinitionVi: 'Thiết kế bài giảng khoa học, áp dụng phương pháp giáo dục hiện đại phát triển năng lực học sinh.',
          expectedEvidenceVi: 'Yêu cầu học phần giáo dục học, phương pháp dạy học chuyên ngành.',
          seedText: 'giáo dục học phương pháp dạy học sư phạm giảng dạy bài giảng lý luận dạy học',
        ),
        RadarAxis(
          code: 'PSY',
          nameVi: 'Tâm lý học Giáo dục',
          nameEn: 'Educational Psychology',
          sectorRoleVi: 'Hiểu tâm sinh lý để tiếp cận học sinh hiệu quả.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Năng lực tư vấn tâm lý học đường, nhận biết đặc điểm tâm lý các độ tuổi học sinh.',
          expectedEvidenceVi: 'Yêu cầu học phần tâm lý học lứa tuổi, tâm lý học giáo dục.',
          seedText: 'tâm lý học lứa tuổi tâm lý học giáo dục giao tiếp sư phạm phát triển tâm lý trẻ em',
        ),
        RadarAxis(
          code: 'DSN',
          nameVi: 'Thiết kế bài giảng',
          nameEn: 'Lesson Design & Curriculum',
          sectorRoleVi: 'Chuẩn bị giáo án và học liệu chương trình đào tạo.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Soạn giáo án, xây dựng bài giảng e-learning tương tác, ứng dụng công nghệ giáo dục.',
          expectedEvidenceVi: 'Yêu cầu các học phần công nghệ giáo dục, thiết kế bài giảng.',
          seedText: 'thiết kế bài giảng công nghệ giáo dục giáo án chương trình học liệu e-learning',
        ),
        RadarAxis(
          code: 'EVAL',
          nameVi: 'Đánh giá học tập',
          nameEn: 'Learning Assessment',
          sectorRoleVi: 'Năng lực đo lường chất lượng học tập khách quan.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Thiết kế đề kiểm tra, phân tích phổ điểm để cải tiến phương pháp sư phạm.',
          expectedEvidenceVi: 'Yêu cầu học phần khảo thí và đánh giá trong giáo dục.',
          seedText: 'đánh giá khảo thí kiểm tra chấm điểm phổ điểm trắc nghiệm đánh giá học tập',
        ),
        RadarAxis(
          code: 'MGT',
          nameVi: 'Quản lý lớp học',
          nameEn: 'Classroom Management',
          sectorRoleVi: 'Duy trì môi trường học tập nề nếp và khuyến khích học sinh.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Năng lực giải quyết xung đột, xây dựng văn hóa lớp học lành mạnh, làm giáo viên chủ nhiệm.',
          expectedEvidenceVi: 'Yêu cầu học phần quản lý hành chính giáo dục, công tác chủ nhiệm.',
          seedText: 'quản lý lớp học công tác chủ nhiệm giáo viên chủ nhiệm kỷ luật lớp học xử lý tình huống',
        ),
        RadarAxis(
          code: 'RES',
          nameVi: 'Nghiên cứu giáo dục',
          nameEn: 'Educational Research',
          sectorRoleVi: 'Khả năng phân tích xu hướng sư phạm và cải tiến giáo dục.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Triển khai đề tài nghiên cứu khoa học sư phạm ứng dụng, khảo sát giáo dục học thực tiễn.',
          expectedEvidenceVi: 'Yêu cầu học phần phương pháp nghiên cứu khoa học giáo dục, chuyên đề sư phạm.',
          seedText: 'nghiên cứu khoa học giáo dục nghiên cứu sư phạm khảo sát đề tài sáng kiến kinh nghiệm',
        ),
        RadarAxis(
          code: 'ETH',
          nameVi: 'Đạo đức sư phạm',
          nameEn: 'Teacher Professional Ethics',
          sectorRoleVi: 'Giữ gìn phẩm chất đạo đức nhà giáo và tác phong sư phạm chuẩn mực.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Gương mẫu, tôn trọng người học, xây dựng môi trường học đường nhân văn và lành mạnh.',
          expectedEvidenceVi: 'Yêu cầu học phần đạo đức nhà giáo, rèn luyện nghiệp vụ sư phạm.',
          seedText: 'đạo đức nhà giáo đạo đức sư phạm ứng xử sư phạm tác phong phẩm chất nhà giáo',
        ),
      ],
    ),

    // 4. Business & Economics
    AcademicDomain(
      id: 'business',
      nameVi: 'Kinh tế & Quản trị Kinh doanh',
      nameEn: 'Economics & Business Administration',
      description: 'kinh tế quản trị kinh doanh marketing tài chính kế toán ngân hàng vi mô vĩ mô đầu tư khởi nghiệp pr quản lý nhân sự',
      axes: [
        RadarAxis(
          code: 'MGT',
          nameVi: 'Quản trị Tổ chức',
          nameEn: 'Business Management',
          sectorRoleVi: 'Lập kế hoạch chiến lược và phối hợp nguồn nhân lực.',
          axisImportance: 0.95,
          axisDefinitionVi: 'Năng lực quản lý nhóm, hoạch định dự án, ra quyết định và tổ chức bộ máy doanh nghiệp.',
          expectedEvidenceVi: 'Yêu cầu học phần quản trị học, hành vi tổ chức, quản trị nhân sự.',
          seedText: 'quản trị học hành vi tổ chức chiến lược quản lý nhân sự lãnh đạo điều hành quản trị dự án',
        ),
        RadarAxis(
          code: 'MKT',
          nameVi: 'Chiến lược Marketing',
          nameEn: 'Marketing Strategy',
          sectorRoleVi: 'Năng lực phân tích thị trường để gia tăng doanh số và thị phần.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Thiết lập chiến dịch truyền thông, nghiên cứu hành vi khách hàng, quản lý kênh phân phối.',
          expectedEvidenceVi: 'Yêu cầu học phần nguyên lý marketing, hành vi người tiêu dùng, digital marketing.',
          seedText: 'marketing nguyên lý marketing quảng cáo truyền thông thương hiệu pr nghiên cứu thị trường',
        ),
        RadarAxis(
          code: 'FIN',
          nameVi: 'Tài chính doanh nghiệp',
          nameEn: 'Corporate Finance',
          sectorRoleVi: 'Quản lý vốn đầu tư và tối ưu hóa hiệu quả tài chính.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Phân tích báo cáo tài chính doanh nghiệp, định giá tài sản, quản lý rủi ro tiền mặt.',
          expectedEvidenceVi: 'Yêu cầu các học phần tài chính doanh nghiệp, tiền tệ ngân hàng, thị trường tài chính.',
          seedText: 'tài chính doanh nghiệp đầu tư tiền tệ ngân hàng cổ phiếu báo cáo tài chính tài chính tiền tệ',
        ),
        RadarAxis(
          code: 'ACC',
          nameVi: 'Kế toán & Kiểm toán',
          nameEn: 'Accounting & Auditing',
          sectorRoleVi: 'Đảm bảo tính chính xác và trung thực của các số liệu kinh tế.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Thực hiện định khoản kế toán, kiểm tra chứng từ giao dịch, lập bảng đối chiếu tài khoản.',
          expectedEvidenceVi: 'Yêu cầu học phần nguyên lý kế toán, kế toán tài chính, kiểm toán căn bản.',
          seedText: 'kế toán nguyên lý kế toán kế toán tài chính kiểm toán thuế chứng từ định khoản',
        ),
        RadarAxis(
          code: 'ECO',
          nameVi: 'Kinh tế học phân tích',
          nameEn: 'Economic Analysis',
          sectorRoleVi: 'Hiểu các nguyên lý kinh tế để nắm bắt thời cơ kinh doanh.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Khả năng phân tích cung cầu, lạm phát, tăng trưởng GDP và tác động chính sách vĩ mô.',
          expectedEvidenceVi: 'Yêu cầu học phần kinh tế vi mô, kinh tế vĩ mô, kinh tế lượng.',
          seedText: 'kinh tế vi mô kinh tế vĩ mô cung cầu kinh tế học thị trường lạm phát chính sách kinh tế',
        ),
        RadarAxis(
          code: 'ANL',
          nameVi: 'Phân tích dữ liệu kinh doanh',
          nameEn: 'Business Data Analysis',
          sectorRoleVi: 'Kỹ năng định lượng phục vụ ra quyết định chiến lược.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Sử dụng các mô hình định lượng, thống kê và công cụ dữ liệu để phân tích tình hình kinh doanh.',
          expectedEvidenceVi: 'Yêu cầu học phần kinh tế lượng, thống kê kinh doanh, phân tích dữ liệu lớn.',
          seedText: 'kinh tế lượng thống kê phân tích dữ liệu data analysis mô hình định lượng tối ưu hóa',
        ),
        RadarAxis(
          code: 'ENT',
          nameVi: 'Khởi nghiệp & Đổi mới',
          nameEn: 'Entrepreneurship & Innovation',
          sectorRoleVi: 'Xây dựng ý tưởng kinh doanh mới và mô hình đổi mới sáng tạo.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Đánh giá tính khả thi dự án, thiết kế mô hình kinh doanh Canvas, quản lý đổi mới công nghệ.',
          expectedEvidenceVi: 'Yêu cầu học phần khởi nghiệp, quản trị đổi mới sáng tạo, dự án kinh doanh.',
          seedText: 'khởi nghiệp sáng tạo mô hình kinh doanh ý tưởng kinh doanh phát triển sản phẩm canvas',
        ),
      ],
    ),

    // 5. Languages & Linguistics
    AcademicDomain(
      id: 'languages',
      nameVi: 'Ngôn ngữ & Ngoại ngữ',
      nameEn: 'Languages & Linguistics',
      description: 'ngôn ngữ ngoại ngữ dịch thuật tiếng anh ngữ pháp biên dịch phiên dịch văn học giao tiếp phát âm ngữ âm nói viết đọc nghe',
      axes: [
        RadarAxis(
          code: 'COM',
          nameVi: 'Kỹ năng Giao tiếp Ngoại ngữ',
          nameEn: 'Foreign Language Communication',
          sectorRoleVi: 'Năng lực giao tiếp thực tế trôi chảy bằng ngoại ngữ mục tiêu.',
          axisImportance: 0.95,
          axisDefinitionVi: 'Phản xạ nghe nói nhạy bén, viết văn bản mạch lạc, đọc hiểu sâu rộng tư liệu ngoại ngữ.',
          expectedEvidenceVi: 'Yêu cầu học phần tiếng Anh/ngoại ngữ thực hành nghe, nói, đọc, viết.',
          seedText: 'nghe nói đọc viết giao tiếp ngoại ngữ phát âm từ vựng đàm thoại thuyết trình tiếng anh',
        ),
        RadarAxis(
          code: 'GRA',
          nameVi: 'Ngữ pháp & Ngôn ngữ học',
          nameEn: 'Grammar & Linguistics',
          sectorRoleVi: 'Nền tảng học thuật cấu trúc tạo từ và đặt câu của ngôn ngữ.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Khả năng phân tích âm vị học, ngữ pháp học đối chiếu, cú pháp ngữ nghĩa câu.',
          expectedEvidenceVi: 'Yêu cầu các học phần ngữ pháp học, âm vị học, dẫn luận ngôn ngữ học.',
          seedText: 'ngự pháp âm vị cú pháp ngôn ngữ học từ vựng dẫn luận ngôn ngữ từ vựng học',
        ),
        RadarAxis(
          code: 'TRA',
          nameVi: 'Biên & Phiên dịch',
          nameEn: 'Translation & Interpretation',
          sectorRoleVi: 'Năng lực truyền tải ngữ nghĩa chính xác giữa hai ngôn ngữ.',
          axisImportance: 0.90,
          axisDefinitionVi: 'Dịch cabin, dịch tài liệu chuyên ngành thương mại, pháp luật, ngoại giao, kỹ thuật.',
          expectedEvidenceVi: 'Yêu cầu các học phần lý thuyết dịch, thực hành biên dịch, thực hành phiên dịch.',
          seedText: 'biên dịch phiên dịch dịch thuật lý thuyết dịch dịch song ngữ dịch cabin',
        ),
        RadarAxis(
          code: 'CUL',
          nameVi: 'Văn hóa & Văn học nước ngoài',
          nameEn: 'Foreign Literature & Culture',
          sectorRoleVi: 'Thấu hiểu bối cảnh văn hóa của quốc gia sử dụng ngôn ngữ.',
          axisImportance: 0.80,
          axisDefinitionVi: 'Phân tích các tác phẩm văn học lớn, lịch sử, văn hóa xã hội của nước bản địa.',
          expectedEvidenceVi: 'Yêu cầu các học phần văn hóa nước ngoài, lịch sử văn học.',
          seedText: 'văn hóa lịch sử văn học văn học anh mỹ đất nước học giao thoa văn hóa',
        ),
        RadarAxis(
          code: 'RES',
          nameVi: 'Nghiên cứu ngôn ngữ',
          nameEn: 'Linguistic Research',
          sectorRoleVi: 'Khả năng phân tích sâu sắc các lý thuyết và hiện tượng ngôn ngữ.',
          axisImportance: 0.75,
          axisDefinitionVi: 'Thực hiện các nghiên cứu về ngữ nghĩa học, đối chiếu ngôn ngữ học hoặc phương pháp dạy ngoại ngữ.',
          expectedEvidenceVi: 'Yêu cầu các học phần phương pháp nghiên cứu ngôn ngữ, tiểu luận chuyên ngành.',
          seedText: 'nghiên cứu ngôn ngữ lý thuyết ngôn ngữ ngữ nghĩa học đối chiếu ngôn ngữ tiểu luận',
        ),
        RadarAxis(
          code: 'ESP',
          nameVi: 'Ngoại ngữ chuyên ngành',
          nameEn: 'Language for Specific Purposes',
          sectorRoleVi: 'Sử dụng ngoại ngữ chuyên sâu trong lĩnh vực thương mại, du lịch hay công nghệ.',
          axisImportance: 0.85,
          axisDefinitionVi: 'Thành thạo thuật ngữ chuyên ngành, viết email thương mại, hợp đồng ngoại thương bằng tiếng Anh/ngoại ngữ.',
          expectedEvidenceVi: 'Yêu cầu các học phần tiếng Anh thương mại, ngoại ngữ du lịch, tiếng Anh chuyên ngành.',
          seedText: 'tiếng anh thương mại ngoại ngữ chuyên ngành thuật ngữ tiếng anh du lịch hợp đồng thương mại',
        ),
      ],
    ),
  ];

  // Fallback domain profile for General Studies / Undefined fields
  static final AcademicDomain _fallbackDomain = AcademicDomain(
    id: 'general',
    nameVi: 'Khoa học & Đào tạo Tổng quát',
    nameEn: 'General & Applied Sciences',
    description: 'đại cương nghiên cứu cơ bản tự nhiên nhân văn logic phương pháp nghiên cứu phương pháp luận',
    axes: [
      RadarAxis(
        code: 'LOG',
        nameVi: 'Tư duy logic',
        nameEn: 'Logical Reasoning',
        sectorRoleVi: 'Khả năng lập luận phản biện khoa học.',
        axisImportance: 0.90,
        axisDefinitionVi: 'Lập luận có cấu trúc, giải quyết vấn đề phức tạp khoa học.',
        expectedEvidenceVi: 'Học phần liên quan: Toán cao cấp, triết học, logic học.',
        seedText: 'logic toán đại số triết học tư duy khoa học giải quyết vấn đề',
      ),
      RadarAxis(
        code: 'RES',
        nameVi: 'Nghiên cứu khoa học',
        nameEn: 'Scientific Research',
        sectorRoleVi: 'Kỹ năng tìm kiếm và kiểm chứng tri thức.',
        axisImportance: 0.85,
        axisDefinitionVi: 'Tra cứu tài liệu, thiết kế đề cương khảo sát, xử lý dữ liệu nghiên cứu.',
        expectedEvidenceVi: 'Học phần liên quan: Phương pháp nghiên cứu khoa học, đồ án.',
        seedText: 'phương pháp nghiên cứu khoa học đồ án thực tập luận văn tiểu luận',
      ),
      RadarAxis(
        code: 'COM',
        nameVi: 'Kỹ năng Truyền thông',
        nameEn: 'Communication Skills',
        sectorRoleVi: 'Khả năng truyền tải thông điệp thuyết phục.',
        axisImportance: 0.80,
        axisDefinitionVi: 'Kỹ năng thuyết trình trước đám đông, soạn thảo văn bản học thuật chuyên nghiệp.',
        expectedEvidenceVi: 'Học phần liên quan: Kỹ năng giao tiếp, soạn thảo văn bản, tiếng Anh chuyên ngành.',
        seedText: 'kỹ năng giao tiếp thuyết trình nói viết soạn thảo văn bản kỹ năng mềm',
      ),
      RadarAxis(
        code: 'COL',
        nameVi: 'Làm việc nhóm',
        nameEn: 'Teamwork & Collaboration',
        sectorRoleVi: 'Khả năng làm việc hiệu quả và phối hợp trong tập thể.',
        axisImportance: 0.85,
        axisDefinitionVi: 'Lắng nghe, chia sẻ trách nhiệm, giải quyết xung đột nhóm và đóng góp chung cho mục tiêu tập thể.',
        expectedEvidenceVi: 'Yêu cầu các học phần kỹ năng làm việc nhóm, các hoạt động dự án học tập.',
        seedText: 'làm việc nhóm teamwork phối hợp tương tác chia sẻ thảo luận giải quyết xung đột',
      ),
      RadarAxis(
        code: 'SLF',
        nameVi: 'Tự học & Phát triển bản thân',
        nameEn: 'Self-Directed Learning & Growth',
        sectorRoleVi: 'Khả năng chủ động cập nhật tri thức và tự định hướng nghề nghiệp.',
        axisImportance: 0.85,
        axisDefinitionVi: 'Thiết lập mục tiêu học tập suốt đời, tự tìm tòi tài liệu học và phản tư phát triển năng lực.',
        expectedEvidenceVi: 'Yêu cầu học phần kỹ năng tự học, phát triển bản thân, định hướng nghề nghiệp.',
        seedText: 'tự học self-directed learning tự nghiên cứu quản lý thời gian mục tiêu cá nhân phát triển bản thân',
      ),
      RadarAxis(
        code: 'ETH',
        nameVi: 'Đạo đức nghề nghiệp',
        nameEn: 'Professional Ethics & Social Responsibility',
        sectorRoleVi: 'Nhận thức sâu sắc về đạo đức và trách nhiệm công dân đối với xã hội.',
        axisImportance: 0.90,
        axisDefinitionVi: 'Tuân thủ các quy tắc đạo đức công vụ, đạo đức nghiên cứu khoa học và bảo vệ môi trường, cộng đồng.',
        expectedEvidenceVi: 'Yêu cầu các học phần giáo dục công dân, pháp luật đại cương, đạo đức học.',
        seedText: 'đạo đức công dân trách nhiệm xã hội đạo đức học pháp luật đại cương liêm chính',
      ),
    ],
  );
}
