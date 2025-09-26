
# MIA - Trợ Lý Tài Chính AI

## 1. Tổng Quan

**MIA (My Investment Assistant)** là một dự án trợ lý tài chính thông minh được phát triển để hỗ trợ khách hàng cá nhân trong việc quản lý tài sản. Hệ thống ứng dụng trí tuệ nhân tạo để tự động phát hiện các khoản tiền nhàn rỗi, đề xuất các cơ hội đầu tư, thực hiện bán chéo sản phẩm (Cross-sale) và cung cấp dịch vụ tư vấn liên tục 24/7.

### Mục Tiêu Dự Án

-   **Quản lý đầu tư thông minh**: Tự động phát hiện và đề xuất phương án tối ưu hóa các khoản tiền nhàn rỗi trong tài khoản của khách hàng.
-   **Bán chéo hiệu quả**: Phân tích hồ sơ khách hàng để tư vấn các sản phẩm, dịch vụ tài chính phù hợp nhất.
-   **Nâng cao trải nghiệm khách hàng**: Cung cấp dịch vụ tư vấn tức thì, giảm thời gian chờ đợi và hoạt động không gián đoạn.
-   **Vượt trội so với tư vấn viên truyền thống**: Khả năng xử lý đa nhiệm, phân tích dữ liệu lớn trong thời gian thực và đưa ra quyết định dựa trên dữ liệu.

## 2. Tính Năng Nổi Bật

### Giao diện Chat Thông minh
-   **Hiển thị định dạng Markdown**: Hỗ trợ đầy đủ bảng, biểu đồ và các định dạng văn bản phức tạp.
-   **Trực quan hóa dữ liệu**: Tự động tạo biểu đồ phân tích giao dịch khi người dùng yêu cầu.
-   **Câu hỏi gợi ý**: Hệ thống tự động đề xuất các câu hỏi liên quan, giúp người dùng tương tác nhanh chóng.
-   **Luồng xác thực giao dịch**: Tích hợp xác thực sinh trắc học (Face ID/Touch ID) để đảm bảo an toàn cho các giao dịch tài chính.
-   **Biểu đồ tương tác**: Hiển thị biểu đồ giao dịch trực quan, cho phép người dùng tương tác để xem chi tiết.

### Xử lý Giọng nói Thời gian thực
Hệ thống được tối ưu hóa để xử lý giọng nói với độ trễ cực thấp, mang lại trải nghiệm trò chuyện tự nhiên và liền mạch.
-   **Tổng độ trễ trung bình**: 1200ms
-   **Chuyển đổi giọng nói thành văn bản (Deepgram)**: 100ms
-   **Xử lý ngôn ngữ (OpenRouter LLM)**: 1000ms
-   **Tổng hợp giọng nói (ElevenLabs Flash v2.5)**: 75ms
-   **Độ trễ truyền tải mạng**: 25ms

## 3. Kiến Trúc Hệ Thống

### Kiến trúc Agent (ReAct)
Hệ thống sử dụng kiến trúc ReAct (Reasoning and Acting) để xử lý các yêu cầu phức tạp của người dùng theo một chu trình logic.
```
Đầu vào người dùng → Lập luận của Agent → Lựa chọn hành động → Thực thi công cụ → Phản hồi
```

### Giao thức Model Context Protocol (MCP)
-   **Thiết kế ưu tiên quyền riêng tư**: Đây là một trong những dự án tiên phong triển khai MCP cho dữ liệu tài chính nhạy cảm. LLM có thể thực hiện các tác vụ phức tạp mà không cần truy cập trực tiếp vào thông tin định danh cá nhân (PII) của khách hàng.
-   **Kiến trúc bảo mật**: Đảm bảo an toàn thông tin ở cấp độ cao nhất thông qua việc cô lập và che (masking) dữ liệu tự động.

### Lớp Hạ tầng (Infrastructure)
-   **Redis Cache Layer**: Tối ưu hóa hiệu suất, giảm số lượng lệnh gọi API không cần thiết và tăng tốc độ phản hồi.
-   **Lưu trữ an toàn**: Quản lý và lưu trữ các thông tin nhạy cảm như API keys và credentials một cách bảo mật.
-   **Live API**: Đồng bộ hóa dữ liệu theo thời gian thực để đảm bảo thông tin luôn được cập nhật.

## 4. Hướng Dẫn Cài Đặt và Vận Hành

### Yêu Cầu Hệ Thống
-   iOS 17.6+
-   Xcode 15.0+
-   Swift 5.9+

### Các Bước Cài Đặt

1.  **Clone repository về máy**:
    ```bash
    git clone https://github.com/minhnghichcode/MIA.git
    cd MIA
    ```

2.  **Mở dự án bằng Xcode**:
    ```bash
    open "MIA By HDBank.xcodeproj"
    ```

3.  **Cấu hình API Keys**:
    Tạo một file mới tên là `Config.xcconfig` trong thư mục gốc của dự án và thêm các khóa sau:
    ```bash
    AGENT_API=https://api.dify.ai/v1/chat-messages
    AGENT_KEY=your_dify_api_key
    VAPI_API_KEY=your_vapi_api_key  
    VAPI_ASSISTANT_ID=your_assistant_id
    ```

4.  **Build và chạy ứng dụng**:
    Nhấn tổ hợp phím `⌘ + R` trong Xcode.

### Hướng Dẫn Sử Dụng

#### Giao diện Chat
1.  Khởi động ứng dụng.
2.  Nhập câu hỏi liên quan đến tài chính hoặc đầu tư vào ô chat.
3.  Hệ thống sẽ tự động hiển thị các biểu đồ và bảng dữ liệu nếu cần thiết.
4.  Sử dụng các câu hỏi gợi ý để tương tác nhanh hơn.
5.  Xác thực các giao dịch tài chính bằng Face ID hoặc Touch ID khi được yêu cầu.

#### Giao diện Giọng nói
1.  Nhấn vào biểu tượng micro để bắt đầu cuộc gọi với MIA.
2.  Trò chuyện một cách tự nhiên. Nội dung cuộc hội thoại sẽ được chuyển thành văn bản và hiển thị trên màn hình.
3.  Sử dụng các nút điều khiển để tắt/mở tiếng trong cuộc gọi.
4.  Nhấn nút kết thúc màu đỏ để dừng cuộc gọi.

## 5. Chi Tiết Kỹ Thuật

### Kiến Trúc Ứng Dụng (MVVM)
Dự án tuân thủ theo mô hình kiến trúc MVVM (Model-View-ViewModel) để đảm bảo sự tách biệt và dễ dàng bảo trì.

```
Views/
├── ChatView.swift          # Giao diện chat chính
├── ChatBubbleView.swift    # Bong bóng tin nhắn
├── TransactionChartView.swift # Biểu đồ trực quan hóa dữ liệu
└── ...

ViewModels/
└── ChatViewModel.swift     # Quản lý logic và trạng thái của view

Models/
├── Message.swift           # Model cho tin nhắn
├── TransactionData.swift   # Model cho dữ liệu giao dịch
└── ...

Services/
├── ChatService.swift      # Tích hợp Dify AI API
├── VapiVoiceService.swift # Quản lý cuộc gọi thoại
└── BiometricService.swift # Dịch vụ xác thực sinh trắc học
```

### Tích hợp Dịch vụ

#### Nền tảng Dify AI
Sử dụng streaming API để tạo ra cuộc hội thoại mượt mà và tương tác với các công cụ của agent.
```swift
// Tạo một stream chat với các công cụ của agent
func streamChat(query: String, conversationId: String?) -> AsyncThrowingStream<ChatEvent, Error>
```

#### Nền tảng Vapi Voice AI
Tích hợp để thực hiện các cuộc hội thoại bằng giọng nói trong thời gian thực.
```swift  
// Bắt đầu cuộc gọi thoại và nhận bản ghi thời gian thực
func startCall(assistantId: String, onTranscript: @escaping (String, Bool) -> Void)
```

## 6. Bảo Mật và Tuân Thủ

### Triển khai Giao thức MCP
-   **Không lộ PII**: Mô hình ngôn ngữ lớn (LLM) xử lý yêu cầu mà không bao giờ tiếp xúc với thông tin định danh cá nhân.
-   **Kiến trúc an toàn**: Mọi truy cập dữ liệu đều được kiểm soát chặt chẽ thông qua các giao thức được định sẵn.
-   **Dấu vết kiểm toán (Audit Trail)**: Ghi lại toàn bộ lịch sử truy cập dữ liệu để phục vụ cho việc kiểm tra và giám sát.
-   **Che dữ liệu**: Tự động ẩn các trường thông tin nhạy cảm.

### Bảo mật Dữ liệu Tài chính
-   Mã hóa dữ liệu cả khi lưu trữ (at rest) và khi truyền tải (in transit).
-   Kiểm soát truy cập dựa trên vai trò (role-based access control).
-   Giám sát và cảnh báo tự động cho các sự cố bảo mật.

### Tính năng Bảo mật trên iOS
-   Sử dụng **Face ID/Touch ID** để xác nhận giao dịch cấp cao.
-   Lưu trữ thông tin nhạy cảm trong **Keychain**.
-   Sử dụng **Certificate Pinning** để ngăn chặn tấn công man-in-the-middle.
-   Bật **App Transport Security (ATS)** để đảm bảo mọi kết nối mạng đều được mã hóa.

## 7. Hướng Dẫn Đóng Góp

### Quy trình Phát triển
1.  Clone repository và cài đặt theo hướng dẫn ở trên.
2.  Tạo một branch mới cho tính năng của bạn:
    ```bash
    git checkout -b feature/your-feature-name
    ```
3.  Sau khi hoàn thành, commit và đẩy code lên repository:
    ```bash
    git commit -m "feat: Mô tả ngắn gọn về tính năng"
    git push origin feature/your-feature-name
    ```
4.  Tạo một Pull Request để review.

### Tiêu chuẩn Mã nguồn
-   Sử dụng **SwiftUI** và **Combine** cho lập trình giao diện và xử lý bất đồng bộ.
-   Tuân thủ nghiêm ngặt mô hình kiến trúc **MVVM**.
-   Sử dụng **async/await** cho các tác vụ đồng thời (concurrency).
-   Viết **Unit Test** với XCTest cho các logic quan trọng.
-   Tài liệu hóa mã nguồn bằng **Swift DocC**.
