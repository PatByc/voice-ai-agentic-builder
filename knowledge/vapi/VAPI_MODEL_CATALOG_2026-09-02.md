# Vapi model catalog — 2026-09-02

Snapshot of models and benchmark values visible in the Vapi Dashboard on 2 September 2026. Values were transcribed from the supplied screenshots. Exact duplicates are retained because they occurred in separate Dashboard views; the screenshot-identification columns have intentionally been omitted.

## How to interpret the data

- Latency, price, Intelligence, WER and Humanness are Vapi Dashboard values, not measurements made by this repository.
- Dashboard WER and Humanness must not be assumed to represent Polish. A model can score highly on Vapi's aggregate benchmark while performing poorly or not being supported in Polish.
- `-` means the value was missing or unreadable in the source screenshot.
- Language support means that a provider accepts Polish; it does not prove that a particular voice has a native Polish accent, correct prosody or reliable pronunciation of names, addresses and numbers.
- Provider/model availability and prices can change. Re-check the Vapi Dashboard before a production decision.

## Current PR004 baseline

| Layer | Provider | Model/configuration | Dashboard latency | Dashboard price | Current evidence |
|---|---|---|---:|---:|---|
| LLM | OpenAI | GPT-4o | approximately 600–670 ms in the catalog | $0.031–$0.050/min depending on entry | Functionally being tested |
| STT | Deepgram | Nova-3, language `pl` | 330 ms | $0.01/min | Polish officially supported; voice tests so far were acceptable |
| TTS | ElevenLabs | Eleven Flash v2.5 | 410 ms | $0.036/min | Polish officially supported; current voice pronunciation was judged acceptable in PR004 calls |

## Polish-focused conclusions

### STT

Deepgram Nova-3 is a defensible baseline. Deepgram explicitly lists Polish (`pl`) for Nova-3 and reports improvements for Polish inflection, endings and soft consonants. The generic Vapi WER of 2.7% is not a Polish-specific result, so PR004 should retain a small Polish corpus test before production.

Recommended STT comparison set:

| Priority | Provider/model | Polish status | Why test it |
|---:|---|---|---|
| 1 | Deepgram Nova-3 | Confirmed | Existing baseline, low latency, already performs acceptably in PR004 |
| 2 | Soniox STT RT v5 | Confirmed | Lower displayed WER and price than Nova-3; designed for real-time multilingual use |
| 3 | ElevenLabs Scribe v2 Realtime | Confirmed | Polish is listed in the provider's excellent, at-most-5%-WER group; must verify the higher Vapi latency |
| 4 | AssemblyAI Universal 3.5 Pro | Confirmed by Vapi multilingual documentation; verify exact Polish configuration | Best displayed WER, but higher cost than Nova-3 |
| 5 | Azure | Confirmed | Native `pl-PL` support; useful independent provider benchmark |

Do not use Flux General Multilingual for Polish unless support changes: Deepgram's current language list for that model does not include Polish.

### TTS

The current Eleven Flash v2.5 is not an English-only model: ElevenLabs explicitly supports Polish. Its main trade-off is speed versus expressiveness, and number normalization is disabled by default. This validates the current prompt rule that makes the LLM spell out hours and numbers.

Recommended TTS comparison set for a Polish legal receptionist:

| Priority | Provider/model | Polish status | Vapi latency | Humanness | Price | Decision note |
|---:|---|---|---:|---:|---:|---|
| 1 | Vapi Voices v2 | 40+ languages; Polish voice quality still requires a live test | 430 ms | 92 | $0.020/min | Best apparent quality/cost challenger; test every female V2 voice for accent |
| 2 | Cartesia Sonic 3.5 | Confirmed | 270 ms | 70 | $0.022/min | Fastest strong Polish candidate; supports pronunciation dictionaries |
| 3 | Inworld TTS 1.5 Max | Confirmed | 540 ms | 77 | $0.005/min | Very low cost with better displayed Humanness than the baseline |
| 4 | Eleven v3 Experimental | Confirmed | 850 ms | 95 | $0.036/min | Highest displayed Humanness, but latency may be too high for calls |
| 5 | Eleven Multilingual v2 | Confirmed | 810 ms | 76 | $0.036/min | Better number normalization and richer output; higher latency |
| 6 | Azure Polish voice | Confirmed (`pl-PL`) | 580 ms | - | $0.011/min | Native Polish catalog and useful independent reference |
| Baseline | Eleven Flash v2.5 | Confirmed | 410 ms | 67 | $0.036/min | Already acceptable, but relatively expensive and lower-scoring |

Do not prioritize xAI despite its Humanness score of 92: Polish is absent from the languages currently accepted by Vapi for xAI TTS. Hume Octave/Octave 2 are also unsuitable because the Hume voices currently exposed by Vapi are English-only.

For every TTS candidate, evaluate the actual Polish voice—not only the model—with the same script. The minimum corpus should include `Faktolex`, `Dominik Marchewka`, all three addresses, Polish diacritics, Monday/Friday duty hours, phone numbers, interruptions and an emotional caller.

## LLM catalog

| # | Model | Latency | Price | Intelligence |
|--:|---|---:|---:|---:|
| 1 | GPT-4o Cluster | 670 ms | $0.031/min | 11 |
| 2 | GPT-5.6 Sol | 1060 ms | $0.029/min | 42 |
| 3 | GPT-5.6 Terra | 870 ms | $0.015/min | 35 |
| 4 | GPT-5.6 Luna | 770 ms | $0.010/min | 27 |
| 5 | GPT-5.5 | 1250 ms | $0.037/min | 36 |
| 6 | GPT Instant (latest) | 700 ms | $0.037/min | - |
| 7 | GPT-5.4 | 800 ms | $0.019/min | 28 |
| 8 | GPT-5.4 Mini | 720 ms | $0.010/min | 17 |
| 9 | GPT-5.4 Nano | 1160 ms | $0.010/min | 18 |
| 10 | GPT-5.2 | 830 ms | $0.014/min | 27 |
| 11 | GPT-5.1 | - | - | - |
| 12 | GPT-5.1 | 810 ms | $0.010/min | 21 |
| 13 | GPT-5 | 840 ms | $0.010/min | 17 |
| 14 | GPT-5 Mini | 820 ms | $0.010/min | 14 |
| 15 | GPT-5 Nano | 710 ms | $0.010/min | 8 |
| 16 | GPT-4.1 | 690 ms | $0.020/min | 20 |
| 17 | GPT-4.1 Mini | 600 ms | $0.010/min | 15 |
| 18 | GPT-4.1 Nano | 450 ms | $0.010/min | 10 |
| 19 | GPT-4o Mini Cluster | 560 ms | $0.010/min | 7 |
| 20 | GPT Realtime Cluster | 450 ms | $0.203/min | - |
| 21 | GPT Realtime Mini | 400 ms | $0.060/min | - |
| 22 | GPT o3 Cluster | 1000 ms | $0.025/min | 31 |
| 23 | GPT o3 Mini Cluster | 1150 ms | $0.014/min | 19 |
| 24 | GPT o4 Mini Cluster | 1100 ms | $0.040/min | 26 |
| 25 | GPT Realtime 2 | 450 ms | $0.645/min | - |
| 26 | GPT-5.4 | 800 ms | $0.019/min | 28 |
| 27 | GPT-5.4 Mini | 720 ms | $0.010/min | 17 |
| 28 | GPT-5.4 Nano | 1160 ms | $0.010/min | 18 |
| 29 | GPT-5.2 | 830 ms | $0.014/min | 27 |
| 30 | GPT-5.2 Chat | 1350 ms | $0.037/min | - |
| 31 | GPT-5.1 | 810 ms | $0.010/min | 21 |
| 32 | GPT-5.1 Chat | 1350 ms | $0.026/min | - |
| 33 | GPT-5 | 840 ms | $0.010/min | 17 |
| 34 | GPT-5 Mini | 820 ms | $0.010/min | 14 |
| 35 | GPT-5 Nano | 710 ms | $0.010/min | 8 |
| 36 | GPT-4.1 2025-04-14 | - | - | - |
| 37 | GPT-4.1 Mini 2025-04-14 | 770 ms | $0.010/min | - |
| 38 | GPT-4.1 Nano 2025-04-14 | 510 ms | $0.010/min | - |
| 39 | GPT-4o 2024-11-20 | 600 ms | $0.050/min | - |
| 40 | GPT-4 Turbo 2024-04-09 | 800 ms | $0.202/min | - |
| 41 | GPT-4 0125 Preview | 800 ms | $0.202/min | - |
| 42 | GPT-4 1106 Preview | 800 ms | $0.202/min | - |
| 43 | GPT-4 0613 | 800 ms | $0.202/min | - |
| 44 | GPT-3.5 Turbo 0125 | 250 ms | $0.010/min | - |
| 45 | GPT-3.5 Turbo 1106 | 250 ms | $0.010/min | - |
| 46 | Claude Sonnet 4.5 | 1430 ms | $0.022/min | 29 |
| 47 | Claude Sonnet 4.6 | 1250 ms | $0.022/min | 37 |
| 48 | Claude Sonnet 5 | 2000 ms | $0.060/min | - |
| 49 | Claude Haiku 4.5 | 750 ms | $0.010/min | 24 |
| 50 | Claude Opus 4.5 | 1560 ms | $0.037/min | 36 |
| 51 | Claude Opus 4.6 | 1910 ms | $0.037/min | 39 |
| 52 | Claude Sonnet 4 | 1030 ms | $0.022/min | 26 |
| 53 | Claude Sonnet 4.5 | 1430 ms | $0.022/min | 29 |
| 54 | Claude Sonnet 4.6 | 1250 ms | $0.022/min | 37 |
| 55 | Claude Haiku 4.5 | 750 ms | $0.010/min | 24 |
| 56 | Claude Haiku 4.5 (Global) | 1000 ms | $0.060/min | - |
| 57 | Claude Opus 4 | 2020 ms | $0.110/min | 26 |
| 58 | Claude Opus 4.5 | - | - | - |
| 59 | Claude 3.7 Sonnet | 1000 ms | $0.022/min | 24 |
| 60 | Claude 3.5 Sonnet | 2000 ms | $0.022/min | 10 |
| 61 | Claude 3.5 Haiku | 840 ms | $0.010/min | 12 |
| 62 | MiniMax M2.7 | 3450 ms | $0.010/min | 39 |
| 63 | Gemini 3.5 Flash | - | - | - |
| 64 | Gemini 3.1 Flash Lite | 800 ms | $0.010/min | 26 |
| 65 | Gemini 3 Flash (Preview) | 1150 ms | $0.010/min | 28 |
| 66 | Gemini 2.5 Pro | 3260 ms | $0.016/min | 26 |
| 67 | Gemini 2.5 Flash | 660 ms | $0.010/min | 14 |
| 68 | Gemini 2.5 Flash Lite | 600 ms | $0.010/min | 7 |
| 69 | Gemma-3 | 1000 ms | $0.060/min | - |
| 70 | Gemini 2.0 Flash Multimodal Live API | 500 ms | $0.010/min | - |
| 71 | Gemini 2.0 Flash Thinking | 800 ms | $0.000/min | 13 |
| 72 | Gemini 1.5 Pro | 1000 ms | $0.016/min | 10 |
| 73 | Gemini 1.0 Pro | 1000 ms | $0.010/min | 3 |
| 74 | Custom LLM | - | - | - |
| 75 | GPT OSS 20B | 410 ms | $0.010/min | 15 |
| 76 | GPT OSS 120B | 500 ms | $0.010/min | 24 |
| 77 | Llama 3.3 70B Versatile | 420 ms | $0.010/min | 9 |
| 78 | Llama 3.1 8B Instant | 340 ms | $0.010/min | 6 |
| 79 | Kimi K2 Instruct 0905 | 730 ms | $0.012/min | 24 |
| 80 | Llama 4 Scout 17B 16e Instruct | 640 ms | $0.010/min | 10 |
| 81 | Compound Beta | 650 ms | $0.010/min | - |
| 82 | Compound Beta Mini | 600 ms | $0.010/min | - |
| 83 | Llama 3.1 8B | 220 ms | $0.010/min | 6 |
| 84 | DeepSeek-V3 | 790 ms | $0.010/min | 21 |
| 85 | DeepSeek-R1 | 7000 ms | $0.010/min | 21 |
| 86 | Grok 4.3 Non-Reasoning | 1910 ms | $0.015/min | 25 |
| 87 | Grok 4.20 Non-Reasoning | 430 ms | $0.015/min | 23 |
| 88 | Grok 4.20 Reasoning | 3610 ms | $0.015/min | 37 |
| 89 | Mistral Large | 1000 ms | $0.040/min | - |
| 90 | Pixtral Large | 1000 ms | $0.040/min | - |
| 91 | Mistral Small | 800 ms | $0.002/min | - |
| 92 | Perplexity AI | 1000 ms | $0.020/min | - |
| 93 | Together AI | 1000 ms | $0.018/min | - |
| 94 | Anyscale | 1000 ms | $0.020/min | - |
| 95 | OpenRouter | 1000 ms | $0.010/min | - |
| 96 | DeepInfra | 1000 ms | $0.014/min | - |
| 97 | Inflection 3 Pi | - | - | - |

Vapi's documented LLM providers at this date include Anthropic, Anthropic Bedrock, Anyscale, Azure OpenAI, Cerebras, Custom LLM, DeepInfra, DeepSeek, Google, Groq, Inflection AI, MiniMax, Mistral, OpenAI, OpenRouter, Perplexity and Together AI. The Dashboard picker remains the authoritative current availability list.

## STT catalog

| # | Provider | Model | Latency | WER | Price |
|--:|---|---|---:|---:|---:|
| 1 | Deepgram | Nova 3 | 330 ms | 2.7% | $0.01/min |
| 2 | Deepgram | Flux General English | 390 ms | 2.3% | $0.01/min |
| 3 | Deepgram | Flux General Multilingual | 440 ms | 2.3% | $0.01/min |
| 4 | Deepgram | Nova 2 | 290 ms | 3.3% | $0.01/min |
| 5 | Deepgram | Nova 3 General | 340 ms | 2.7% | $0.01/min |
| 6 | Deepgram | Nova 3 Medical | 360 ms | 2.7% | $0.01/min |
| 7 | Deepgram | Nova 2 General | 360 ms | 3.3% | $0.01/min |
| 8 | Deepgram | Nova 2 Meeting | 260 ms | 3.3% | $0.01/min |
| 9 | Deepgram | Nova 2 Phonecall | 320 ms | 3.3% | $0.01/min |
| 10 | Deepgram | Nova 2 Finance | 590 ms | 3.3% | $0.01/min |
| 11 | Deepgram | Nova 2 Conversational AI | - | - | - |
| 12 | Deepgram | Nova 2 Voicemail | 170 ms | 3.3% | $0.01/min |
| 13 | Deepgram | Nova 2 Video | 360 ms | 3.3% | $0.01/min |
| 14 | Deepgram | Nova 2 Medical | 370 ms | 3.3% | $0.01/min |
| 15 | Deepgram | Nova 2 Drive Thru | 390 ms | 3.3% | $0.01/min |
| 16 | Deepgram | Nova 2 Automotive | - | - | - |
| 17 | Soniox | STT RT v5 | 410 ms | 1.8% | $0.004/min |
| 18 | Soniox | STT RT v4 | 550 ms | 2.0% | $0.004/min |
| 19 | Cartesia | Ink 2 | 580 ms | - | $0.01/min |
| 20 | Cartesia | Ink Whisper | 340 ms | 4.6% | $0.003/min |
| 21 | xAI | xAI STT | 350 ms | 3.0% | $0.007/min |
| 22 | OpenAI | GPT-4o Transcribe | 1040 ms | - | $0.012/min |
| 23 | OpenAI | GPT-4o Mini Transcribe | - | - | $0.006/min |
| 24 | AssemblyAI | Universal 3.5 Pro | 390 ms | 1.2% | $0.015/min |
| 25 | AssemblyAI | Universal Streaming (English) | 390 ms | 3.9% | $0.005/min |
| 26 | AssemblyAI | Universal Streaming (Multilingual) | 390 ms | 3.9% | $0.005/min |
| 27 | Speechmatics | Speechmatics | 820 ms | 2.2% | $0.035/min |
| 28 | Microsoft Azure | Azure | 750 ms | 1.8% | $0.034/min |
| 29 | Gladia | Solaria | 1030 ms | 5.8% | $0.025/min |
| 30 | Gladia | Accurate | 1010 ms | 5.6% | $0.025/min |
| 31 | Gladia | Fast | 1040 ms | 5.5% | $0.025/min |
| 32 | ElevenLabs | Scribe v1 | 420 ms | 3.0% | $0.013/min |
| 33 | ElevenLabs | Scribe v2 | 570 ms | 2.4% | $0.013/min |
| 34 | ElevenLabs | Scribe v2 Realtime | 870 ms | 2.8% | $0.013/min |
| 35 | Google | Gemini 2.0 Flash | - | - | - |
| 36 | Google | Gemini 2.0 Flash | 650 ms | - | $0.004/min |
| 37 | Google | Gemini 2.0 Flash Lite | 580 ms | - | $0.0003/min |
| 38 | Google | Gemini 1.5 Pro | 590 ms | - | $0.004/min |
| 39 | OpenAI | Whisper | 460 ms | - | $0.022/min |

## TTS catalog

| # | Provider | Model | Latency | Humanness | Price |
|--:|---|---|---:|---:|---:|
| 1 | ElevenLabs | Eleven Flash v2.5 | 410 ms | 67 | $0.036/min |
| 2 | Vapi | Vapi Voices - Version 2 | 430 ms | 92 | $0.02/min |
| 3 | Vapi | Vapi Voices - Version 1 | 810 ms | 76 | $0.036/min |
| 4 | Cartesia | Sonic 3.5 | 270 ms | 70 | $0.022/min |
| 5 | Cartesia | Sonic 3.5 (2026-05-04) | 270 ms | - | $0.022/min |
| 6 | Cartesia | Sonic 3 | 310 ms | 65 | $0.022/min |
| 7 | Cartesia | Sonic 3 | 310 ms | 65 | $0.022/min |
| 8 | Cartesia | Sonic 3 (2026-01-12) | 290 ms | - | $0.022/min |
| 9 | Cartesia | Sonic 3 (2025-10-27) | 510 ms | - | $0.022/min |
| 10 | Cartesia | Sonic 2 | 260 ms | 65 | $0.022/min |
| 11 | Cartesia | Sonic 2 (2025-06-11) | 300 ms | - | $0.022/min |
| 12 | Cartesia | Sonic English | - | - | - |
| 13 | Cartesia | Sonic English | 210 ms | - | $0.022/min |
| 14 | Cartesia | Sonic Multilingual | 260 ms | - | $0.022/min |
| 15 | Cartesia | Sonic Preview | 340 ms | - | $0.022/min |
| 16 | Cartesia | Sonic | 250 ms | 0 | $0.022/min |
| 17 | xAI | xAI | 430 ms | 92 | $0.02/min |
| 18 | Deepgram | Aura | 280 ms | - | $0.011/min |
| 19 | Deepgram | Aura 2 | 370 ms | - | $0.011/min |
| 20 | OpenAI | GPT-4o Mini TTS | - | - | $0.01/min |
| 21 | OpenAI | TTS 1 HD | - | - | $0.011/min |
| 22 | OpenAI | TTS 1 | - | - | $0.01/min |
| 23 | Inworld | Inworld TTS 1 | 520 ms | - | $0.008/min |
| 24 | Inworld | Inworld TTS 1.5 Max | 540 ms | 77 | $0.005/min |
| 25 | Inworld | Inworld TTS 1.5 Mini | 410 ms | - | $0.003/min |
| 26 | Inworld | Inworld TTS 2 | 810 ms | 70 | $0.013/min |
| 27 | MiniMax | Speech 02 Turbo | 390 ms | 68 | $0.03/min |
| 28 | Microsoft Azure | Azure | 580 ms | - | $0.011/min |
| 29 | Rime AI | Mist v2 | 370 ms | - | $0.011/min |
| 30 | Rime AI | Mist | 330 ms | - | $0.011/min |
| 31 | Rime AI | Arcana | 1650 ms | - | $0.011/min |
| 32 | LMNT | LMNT | 340 ms | - | $0.058/min |
| 33 | Neuphonic | Neu HQ | 470 ms | 39 | $0.01/min |
| 34 | Neuphonic | Neu Fast | 410 ms | - | $0.01/min |
| 35 | Smallest AI | Lightning | 630 ms | 43 | $0.02/min |
| 36 | ElevenLabs | Eleven Multilingual v2 | 810 ms | 76 | $0.036/min |
| 37 | ElevenLabs | Eleven Turbo v2 | 520 ms | 74 | $0.036/min |
| 38 | ElevenLabs | Eleven Turbo v2.5 | 480 ms | 73 | $0.036/min |
| 39 | ElevenLabs | Eleven Flash v2 | 380 ms | 76 | $0.036/min |
| 40 | ElevenLabs | Eleven English v1 | 1370 ms | - | $0.036/min |
| 41 | ElevenLabs | Eleven v3 (Experimental) | 850 ms | 95 | $0.036/min |
| 42 | Hume | Octave | 900 ms | - | $0.01/min |
| 43 | Hume | Octave 2 | 540 ms | - | $0.005/min |
| 44 | Custom | Custom Voice | 730 ms | - | - |

## Sources checked on 2026-09-02

- [Vapi model providers](https://docs.vapi.ai/providers/model/overview)
- [Vapi multilingual support and provider comparison](https://docs.vapi.ai/customization/multilingual)
- [Vapi Voices v2](https://docs.vapi.ai/providers/voice/vapi-voices)
- [Vapi ElevenLabs voice support](https://docs.vapi.ai/providers/voice/elevenlabs)
- [Vapi Cartesia voice support](https://docs.vapi.ai/providers/voice/cartesia)
- [Vapi Inworld voice support](https://docs.vapi.ai/providers/voice/inworld)
- [Vapi xAI voice support](https://docs.vapi.ai/providers/voice/xai)
- [Deepgram model and language support](https://developers.deepgram.com/docs/models-languages-overview/)
- [ElevenLabs model and language support](https://elevenlabs.io/docs/overview/models)
- [ElevenLabs Scribe STT support](https://elevenlabs.io/docs/overview/capabilities/speech-to-text/)
- [Cartesia Sonic 3.5](https://docs.cartesia.ai/build-with-cartesia/tts-models/latest)
- [Microsoft Azure Speech language support](https://learn.microsoft.com/en-us/azure/ai-services/Speech-Service/language-support)
- [Vapi Soniox transcriber](https://docs.vapi.ai/providers/transcriber/soniox)
- [Vapi Gladia transcriber](https://docs.vapi.ai/providers/transcriber/gladia)
- [Vapi Hume voice support](https://docs.vapi.ai/providers/voice/hume)

