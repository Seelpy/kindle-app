import SwiftUI

private enum AppPalette {
    static let canvas = Color(red: 0.93, green: 0.92, blue: 0.89)
    static let surface = Color(red: 0.99, green: 0.985, blue: 0.965)
    static let ink = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let muted = Color(red: 0.38, green: 0.36, blue: 0.33)
    static let accent = Color(red: 0.16, green: 0.29, blue: 0.24)
}

struct ContentView: View {
    @EnvironmentObject private var store: ReadingStore
    @EnvironmentObject private var aiProxy: AIProxyStore
    @StateObject private var screenShare = KindleScreenShareStore()
    @State private var showReleaseConfirmation = false
    @State private var showScreenShare = false
    @State private var showAIStatus = false
    @State private var closingNote = "Начни с разговора у окна"

    var body: some View {
        ZStack {
            AppPalette.canvas.ignoresSafeArea()

            if let book = store.state.book {
                MacSurface(book: book, showReleaseConfirmation: $showReleaseConfirmation, showScreenShare: $showScreenShare, showAIStatus: $showAIStatus, closingNote: $closingNote)
                    .padding(24)
            } else {
                EmptyBookView()
            }
        }
        .foregroundStyle(AppPalette.ink)
        .tint(AppPalette.accent)
        .preferredColorScheme(.light)
        .confirmationDialog("Отпустить эту книгу?", isPresented: $showReleaseConfirmation) {
            Button("Отпустить книгу") { store.releaseBook() }
            Button("Продолжить читать", role: .cancel) {}
        } message: {
            Text("Прогресс и заметка останутся сохранены. К книге всегда можно вернуться.")
        }
        .sheet(isPresented: $showScreenShare) {
            KindleScreenShareView()
                .environmentObject(screenShare)
                .onAppear {
                    if !screenShare.isStreaming {
                        screenShare.connect()
                    }
                }
        }
        .sheet(isPresented: $showAIStatus) {
            AIStatusView()
                .environmentObject(aiProxy)
        }
    }
}

private struct MacSurface: View {
    @EnvironmentObject private var store: ReadingStore
    @EnvironmentObject private var aiProxy: AIProxyStore
    let book: ActiveBook
    @Binding var showReleaseConfirmation: Bool
    @Binding var showScreenShare: Bool
    @Binding var showAIStatus: Bool
    @Binding var closingNote: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { store.simulateConnection() } label: { Image(systemName: "line.3.horizontal") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Переключить состояние соединения")
                Spacer()
                VStack(spacing: 1) {
                    Text("Ещё пять").font(.system(.title3, design: .serif, weight: .semibold))
                    Text("спокойный ритм чтения")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppPalette.muted)
                }
                Spacer()
                Button("Экран Kindle") { showScreenShare = true }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button { showAIStatus = true } label: {
                    Label(aiProxy.status.title, systemImage: aiProxy.status.symbol)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .layoutPriority(1)
            }
            .padding(.horizontal, 28)
            .frame(height: 66)
            .overlay(alignment: .bottom) { Divider() }

            if store.state.session.status == .reading || store.state.session.status == .complete {
                SessionView(book: book, closingNote: $closingNote, showScreenShare: $showScreenShare)
            } else {
                StartView(book: book, showReleaseConfirmation: $showReleaseConfirmation, showScreenShare: $showScreenShare)
            }
        }
        .background(AppPalette.surface)
        .foregroundStyle(AppPalette.ink)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 14)
    }
}

private struct AIStatusView: View {
    @EnvironmentObject private var aiProxy: AIProxyStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("AI-помощник для чтения")
                    .font(.system(size: 30, design: .serif))
                Spacer()
                Button("Закрыть") { dismiss() }
            }

            Label(aiProxy.status.title, systemImage: aiProxy.status.symbol)
                .font(.title3)

            Text("KOAssistant работает внутри KOReader, а запросы передаёт через этот Mac. Книжный текст отправляется только после вашего разрешения в настройках приватности KOAssistant.")
                .foregroundStyle(AppPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Адрес для Kindle").font(.caption).foregroundStyle(.secondary)
                Text(aiProxy.endpoint + "/chat/completions")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            HStack {
                Button("Запустить и проверить") {
                    Task { await aiProxy.startIfNeeded() }
                }
                .buttonStyle(.borderedProminent)
                Button("Обновить статус") {
                    Task { await aiProxy.refresh() }
                }
            }
        }
        .padding(28)
        .frame(width: 620, height: 310)
        .background(AppPalette.surface)
        .foregroundStyle(AppPalette.ink)
        .preferredColorScheme(.light)
    }
}

private struct KindleScreenShareView: View {
    @EnvironmentObject private var screenShare: KindleScreenShareStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Экран Kindle Scribe")
                        .font(.system(size: 28, design: .serif))
                    Text("Только просмотр · локальная сеть · строгая проверка SSH")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Закрыть") { dismiss() }
            }

            HStack(spacing: 10) {
                TextField("IP-адрес Kindle", text: $screenShare.host)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 190)
                TextField("Порт", text: $screenShare.port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 76)

                Button(screenShare.isStreaming ? "Остановить" : "Подключить") {
                    screenShare.connect()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
                Button { screenShare.rotateLeft() } label: { Image(systemName: "rotate.left") }
                    .accessibilityLabel("Повернуть влево")
                Button { screenShare.rotateRight() } label: { Image(systemName: "rotate.right") }
                    .accessibilityLabel("Повернуть вправо")
            }

            Label(screenShare.status.title, systemImage: screenShare.isStreaming ? "dot.radiowaves.left.and.right" : "lock.shield")
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.88, green: 0.88, blue: 0.86))

                if let frame = screenShare.frame {
                    Image(nsImage: frame)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .rotationEffect(.degrees(Double(screenShare.rotation)))
                        .padding(20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.on.rectangle.slash")
                            .font(.system(size: 42, weight: .light))
                        Text("Введите адрес Kindle и подключитесь")
                            .font(.system(size: 20, design: .serif))
                        Text("На Kindle должен быть заранее включён SSH в KOReader и добавлен ваш публичный ключ.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }
                }
            }
            .frame(minHeight: 570)
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 760)
        .background(AppPalette.surface)
        .foregroundStyle(AppPalette.ink)
        .preferredColorScheme(.light)
        .onDisappear { screenShare.disconnect() }
    }
}

private struct StartView: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook
    @Binding var showReleaseConfirmation: Bool
    @Binding var showScreenShare: Bool

    var body: some View {
        VStack(spacing: 28) {
            Text("Когда продолжим?")
                .font(.system(size: 56, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 16) {
                ForEach(ReadingMoment.allCases) { moment in
                    MomentButton(moment: moment, selected: store.state.session.selectedMoment == moment) {
                        store.select(moment)
                    }
                }
            }

            Label("Только 5 страниц — можно остановиться раньше", systemImage: "book")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .bottom, spacing: 34) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(book.author.uppercased()).font(.system(size: 11, design: .serif)).tracking(1)
                    Text(book.title).font(.system(size: 40, design: .serif))
                    Text("Продолжить чтение с:").font(.system(size: 12, design: .serif)).padding(.top, 8)
                    Text("\(book.chapter) · страница \(book.page)").font(.system(size: 14, weight: .semibold, design: .serif))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Заметка для себя:").font(.caption).foregroundStyle(.secondary)
                    Text(book.resumeNote).font(.system(size: 27, design: .serif)).italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            startButton
                .buttonStyle(.borderedProminent)
                .tint(AppPalette.accent)

            Button("Отпустить книгу") { showReleaseConfirmation = true }
                .buttonStyle(.plain)
                .fontWeight(.semibold)

            Label(store.connection.rawValue, systemImage: store.connection == .connected ? "checkmark.circle" : "wifi.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(42)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var startButton: some View {
        Button {
            store.startSession()
            showScreenShare = true
        } label: {
            Label(store.state.session.selectedMoment == .now ? "Начать 5 страниц" : store.state.session.selectedMoment.title, systemImage: "book")
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .disabled(store.state.session.selectedMoment != .now)
    }
}

private struct MomentButton: View {
    let moment: ReadingMoment
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: moment.symbol).font(.system(size: 36, weight: .light))
                Text(moment.title).font(.system(size: 15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 126)
            .background(selected ? Color.blue.opacity(0.05) : Color.clear)
            .overlay { RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.blue : Color.secondary.opacity(0.45), lineWidth: selected ? 2 : 1) }
            .overlay(alignment: .topLeading) {
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 14)).padding(10)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SessionView: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook
    @Binding var closingNote: String
    @Binding var showScreenShare: Bool

    var body: some View {
        VStack(spacing: 26) {
            Text(store.state.session.status == .complete ? "Пять страниц прочитаны" : "Читаем без спешки")
                .font(.system(size: 46, design: .serif))
            Text("\(store.state.session.pagesCompleted) из \(store.state.session.goalPages) страниц")
                .font(.title3)
            ProgressView(value: Double(store.state.session.pagesCompleted), total: Double(store.state.session.goalPages))
                .frame(maxWidth: 440)

            if store.state.session.status == .complete {
                TextField("Что нужно помнить, когда вернёшься?", text: $closingNote)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 500)
                Button("Закончить сеанс") { store.finishSession(note: closingNote) }
                    .buttonStyle(.borderedProminent)
                    .tint(AppPalette.accent)
                    .controlSize(.large)
            } else {
                HStack(spacing: 12) {
                    Button("Показать экран Kindle") { showScreenShare = true }
                    Button("Страница прочитана") { store.nextPage() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppPalette.accent)
                }
                .controlSize(.large)
            }

            Text("\(book.title) · \(book.chapter)").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(44)
    }
}

private struct EmptyBookView: View {
    @EnvironmentObject private var store: ReadingStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.closed").font(.system(size: 48, weight: .light))
            Text("Место для следующей книги").font(.system(size: 44, design: .serif))
            Text("Ты не бросил книгу — ты освободил внимание.").foregroundStyle(.secondary)
            Button("Вернуть «Анну Каренину»") { store.restoreDemoBook() }.buttonStyle(.borderedProminent)
        }
    }
}
