# MIA - AI Financial Assistant 🤖💰

## Giới Thiệu

**MIA (My Investment Assistant)** là dự án AI hackathon được thiết kế để hỗ trợ khách hàng cá nhân trong việc quản lý tài chính thông minh. Hệ thống sử dụng trí tuệ nhân tạo để phát hiện tiền nhàn rỗi, tư vấn đầu tư, thực hiện Cross-sale và cung cấp dịch vụ tư vấn tài chính 24/7.

### 🎯 Mục Tiêu Dự Án

- **Quản lý đầu tư thông minh**: Phát hiện và tối ưu hóa tiền nhàn rỗi
- **Cross-sale thông minh**: Tư vấn sản phẩm phù hợp với profile khách hàng  
- **Nâng cao trải nghiệm**: Giảm waiting time, hoạt động 24/7
- **Vượt trội tư vấn viên**: AI có thể xử lý đa tác vụ và phân tích dữ liệu real-time

## ✨ Tính Năng Chính

### 🗣️ Giao Diện Đa Phương Thức

#### 1. Chat Interface
- Hỗ trợ **Markdown rendering** với bảng, biểu đồ
- **Visualization** dữ liệu giao dịch tự động
- **Suggested questions** thông minh
- **Confirmation flow** với Face ID/Touch ID
- Hiển thị **transaction charts** interactive

#### 2. Real-time Voice Processing
**Hiệu suất cao với độ trễ thấp:**
- **Median Latency**: 1200ms
- **Transcriber (Deepgram)**: 100ms
- **LLM Model (OpenRouter)**: 1000ms  
- **Voice Synthesis (ElevenLabs Flash v2.5)**: 75ms
- **Transport Layer**: 25ms

### 🏗️ Kiến Trúc Agent

#### ReAct Agent Architecture
```
User Input → Agent Reasoning → Action Selection → Tool Execution → Response
```

#### Model Context Protocol (MCP)
- **Tiên phong triển khai MCP** cho dữ liệu nhạy cảm tài chính
- **Privacy-First Design**: LLM thực hiện tác vụ phức tạp mà không truy cập thông tin định danh khách hàng
- **Secure Architecture**: Bảo mật thông tin cấp độ cao
- **Data isolation** và **masking** tự động

#### Infrastructure Layer
- **Redis Cache Layer**: Tối ưu hiệu suất và giảm API calls
- **Secure Storage**: Bảo mật credentials và sensitive data
- **Live API**: Real-time data synchronization

## 📱 Cài Đặt và Sử Dụng

### Yêu Cầu Hệ Thống
- iOS 17.6+
- Xcode 15.0+
- Swift 5.9+

### 🚀 Cài Đặt

1. **Clone repository**
```bash
git clone https://github.com/minhnghichcode/MIA.git
cd MIA
```

2. **Mở project trong Xcode**
```bash
open "MIA By HDBank.xcodeproj"
```

3. **Cấu hình API Keys** (tạo file `Config.xcconfig` hoặc sử dụng Environment Variables):
```bash
AGENT_API=https://api.dify.ai/v1/chat-messages
AGENT_KEY=your_dify_api_key
VAPI_API_KEY=your_vapi_api_key  
VAPI_ASSISTANT_ID=your_assistant_id
```

4. **Build và Run**
```bash
⌘ + R
```

### 🎮 Sử Dụng

#### Chat Interface
1. **Khởi động app** → Xem splash screen
2. **Chat với MIA**: Gõ câu hỏi về tài chính, đầu tư
3. **Xem visualization**: Charts và bảng dữ liệu tự động hiển thị
4. **Suggested questions**: Tap để hỏi nhanh
5. **Xác thực giao dịch**: Sử dụng Face ID/Touch ID

#### Voice Interface  
1. **Tap icon mic** để bắt đầu voice call
2. **Nói chuyện tự nhiên** với MIA
3. **Real-time transcription** hiển thị trong chat
4. **Mute/Unmute** trong cuộc gọi
5. **Kết thúc** bằng nút đỏ

#### Transaction Analysis
- **Tự động parse** dữ liệu giao dịch từ APIs
- **Visualize** thu chi theo tháng
- **Đề xuất** cơ hội đầu tư dựa trên cash flow
- **Cross-sell** sản phẩm phù hợp

## 🏛️ Kiến Trúc Kỹ Thuật

### App Architecture (MVVM)
```
Views/
├── ChatView.swift          # Main chat interface
├── ChatBubbleView.swift    # Message bubbles
├── TransactionChartView.swift # Data visualization
├── ConfirmationView.swift  # Transaction confirmation
└── SuggestedQuestionsView.swift

ViewModels/
└── ChatViewModel.swift     # Business logic & state management

Models/
├── Message.swift           # Chat message model
├── TransactionData.swift   # Financial data model
└── ThemeColors.swift      # UI theme system

Services/
├── ChatService.swift      # Dify API integration
├── VapiVoiceService.swift # Voice call management
└── BiometricService.swift # Face ID/Touch ID
```

### Integration Services

#### Dify AI Platform
```swift
// Streaming chat với agent tools
func streamChat(query: String, conversationId: String?) -> AsyncThrowingStream<ChatEvent, Error>
```

#### Vapi Voice AI
```swift  
// Real-time voice conversation
func startCall(assistantId: String, onTranscript: @escaping (String, Bool) -> Void)
```

#### Financial APIs (MCP Integration)
- Secure data access through MCP protocol
- Transaction history and analysis
- Investment opportunity detection  
- Risk assessment and recommendations

## 🔒 Bảo Mật & Tuân Thủ

### Privacy-First MCP Implementation
- **Zero PII Exposure**: LLM không bao giờ thấy thông tin định danh
- **Secure Architecture**: Tất cả data access qua controlled protocols
- **Audit Trail**: Log đầy đủ mọi truy cập dữ liệu
- **Data Masking**: Tự động che giấu sensitive fields

### Financial Data Security
- **Encryption at rest và in transit**
- **Access control** với role-based permissions
- **Monitoring và alerting** cho security incidents

### iOS Security Features
- **Face ID/Touch ID** cho transaction confirmation
- **Keychain** storage cho sensitive data
- **Certificate pinning** cho API calls
- **App Transport Security** (ATS) enabled

## 🚀 Roadmap & Tính Năng Tương Lai

### Phase 2: Advanced AI Features
- [ ] **Portfolio optimization** với ML
- [ ] **Sentiment analysis** từ news/social media
- [ ] **Predictive analytics** cho market trends
- [ ] **Multi-language support** (English, Chinese)

### Phase 3: Enterprise Integration  
- [ ] **CRM integration** với external systems
- [ ] **Risk management** system integration
- [ ] **Analytics reporting** automation
- [ ] **A/B testing** framework

### Phase 4: Advanced Voice Features
- [ ] **Emotion detection** trong voice
- [ ] **Multi-speaker** conversation support
- [ ] **Voice biometrics** cho authentication
- [ ] **Offline voice** processing

## 👥 Đóng Góp

### Development Setup
```bash
# Clone và setup
git clone https://github.com/minhnghichcode/MIA.git
cd MIA

# Install dependencies (tự động qua Xcode)
# Tạo branch feature
git checkout -b feature/your-feature-name

# Commit và push
git commit -m "feat: add new feature"
git push origin feature/your-feature-name
```

### Code Standards
- **SwiftUI** và **Combine** cho reactive programming
- **MVVM** architecture pattern
- **Async/await** cho concurrent programming  
- **Unit testing** với XCTest
- **Documentation** với Swift DocC

> **"AI không thay thế con người, mà tăng cường khả năng con người trong lĩnh vực tài chính."** - MIA Hackathon Team
