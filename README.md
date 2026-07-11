# 🎌 Sakura AI Tutor

Learn Japanese pronunciation through natural conversation with an AI teacher.

**Sakura** is your personal Japanese pronunciation coach. You speak **English**, she teaches you how to say things in **Japanese**, breaks down the pronunciation, and gives you real-time feedback.

---

## ✨ Features

- **AI Conversation Practice** — Talk to Sakura like a real teacher. Ask how to say anything in Japanese.
- **Pronunciation Scoring** — Record your Japanese attempts and get scored on accuracy (Whisper confidence + text similarity + LLM evaluation).
- **Grammar Corrections** — Real-time feedback on particle usage, verb conjugation, keigo (honorifics), and more.
- **TTS Audio Playback** — Hear correct Japanese pronunciation with natural Microsoft Edge TTS (ja-JP-Nanami voice).
- **JLPT Level Targeting** — Practice at your level: N5 (beginner) to N1 (advanced).
- **Free Tier** — 5 lessons/day. Upgrade for unlimited access.

---

## 🏗 Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Flutter App │────▶│  FastAPI Backend  │────▶│ DeepSeek V4  │
│ (iOS/Android)│    │  (Fly.io server)  │    │  (AI Teacher) │
│             │◀───│                   │◀───│              │
│ record pkg  │     │  + Whisper (STT)  │     │  edge-tts    │
│ just_audio  │     │  + Scoring Engine │     │  (TTS)       │
└─────────────┘     └──────────────────┘     └──────────────┘
```

### Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile | **Flutter** | Cross-platform iOS + Android |
| Backend | **FastAPI** (Python) | Async, great for audio processing |
| AI | **DeepSeek V4** | $0.14/M tokens, near GPT-4o quality |
| STT | **faster-whisper** | Local inference, free, ~140MB model |
| TTS | **edge-tts** (Microsoft) | Free, excellent Japanese voice |
| Auth | **Bearer token** | Simple MVP auth (upgrade to Supabase planned) |
| Deploy | **Fly.io** | ~$3.41/month, Tokyo region |
| Payments | **RevenueCat** (planned) | Unified App Store + Play Store subscriptions |

---

## 📁 Project Structure

```
ai-japanese-tutor/
├── backend/               # FastAPI Python backend
│   ├── app/
│   │   ├── main.py        # API entry point + CORS + lifespan
│   │   ├── routers/
│   │   │   ├── chat.py    # POST /api/v1/chat (core endpoint)
│   │   │   ├── user.py    # User profile management
│   │   │   ├── auth.py    # Bearer token auth
│   │   │   └── health.py  # Health check
│   │   └── services/
│   │       ├── tutor.py   # DeepSeek V4 conversation engine
│   │       ├── stt_service.py  # Whisper speech-to-text
│   │       ├── tts_service.py  # edge-tts voice synthesis
│   │       └── scoring.py # Pronunciation scoring algorithm
│   ├── Dockerfile
│   └── fly.toml
│
├── mobile/                # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart      # Entry point + Provider setup
│   │   ├── app.dart       # Router + theme
│   │   ├── config/        # API constants
│   │   ├── models/        # Data models
│   │   ├── services/      # API client, audio, state management
│   │   ├── screens/       # 6 screens (splash, home, lesson, etc.)
│   │   └── widgets/       # Chat bubble, record button, score cards
│   └── pubspec.yaml
│
├── demo/                  # CLI prototype (Phase 0 validation)
│   └── main.py            # Run this first to test the AI
│
└── supabase/
    └── migrations/        # Database schema (for future use)
```

---

## 🚀 Quick Start

### 1. Try the AI (no phone needed)

```bash
cd demo
pip install -r requirements.txt
export LLM_API_KEY="your-deepseek-api-key"
python main.py --text
```

Type English, get Japanese teaching. This validates the core AI quality before building anything.

### 2. Run the backend locally

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env  # Add your LLM_API_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8123
```

### 3. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

> The mobile app points to our hosted API at `sakura-tutor-api.fly.dev` by default. Change in `lib/config/constants.dart` to use localhost.

---

## 🎯 Pronunciation Scoring Algorithm

Three signals weighted into a single 0-100 score:

| Signal | Weight | Source |
|--------|--------|--------|
| Acoustic Confidence | 30% | Whisper per-segment probabilities |
| Text Accuracy | 30% | Levenshtein distance (expected vs transcribed) |
| LLM Evaluation | 40% | DeepSeek linguistic assessment |

**Grade mapping**: Excellent (85+), Good (70-84), Fair (50-69), Needs Work (<50)

---

## 💰 Business Model

- **Free tier**: 5 lessons/day
- **Pro**: $9.99/month — unlimited lessons
- **Cost to serve**: ~$0.003/user/month (DeepSeek API)
- **Infrastructure**: ~$4/month (Fly.io + Supabase free tier)

---

## 🗺 Roadmap

- [x] Phase 0: CLI prototype (AI validation)
- [x] Phase 1: Backend API (FastAPI + Fly.io)
- [x] Phase 2: Mobile app (Flutter)
- [ ] RevenueCat subscription integration
- [ ] Supabase auth + progress tracking
- [ ] Multiple language support (Chinese, Korean, French)
- [ ] Push notifications & streak tracking
- [ ] App Store & Play Store launch

---

## 🤝 Contributing

This is an open source project — contributions welcome!

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- [DeepSeek](https://deepseek.com/) — LLM API
- [OpenAI Whisper](https://github.com/openai/whisper) — Speech recognition
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) — Local Whisper inference
- [edge-tts](https://github.com/rany2/edge-tts) — Text-to-speech
- [Flutter](https://flutter.dev/) — Mobile framework
- [Fly.io](https://fly.io/) — Server deployment
