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
    @StateObject private var screenShare = KindleScreenShareStore()
    @State private var showReleaseConfirmation = false
    @State private var showScreenShare = false
    @State private var closingNote = "Начни с разговора у окна"

    var body: some View {
        ZStack {
            AppPalette.canvas.ignoresSafeArea()

            if let book = store.state.book {
                MacSurface(book: book, showReleaseConfirmation: $showReleaseConfirmation, showScreenShare: $showScreenShare, closingNote: $closingNote)
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
        }
    }
}

private struct MacSurface: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook
    @Binding var showReleaseConfirmation: Bool
    @Binding var showScreenShare: Bool
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
                Text(Date.now, format: .dateTime.day().month(.wide).year()).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)
            .frame(height: 66)
            .overlay(alignment: .bottom) { Divider() }

            if store.state.session.status == .reading || store.state.session.status == .complete {
                SessionView(book: book, closingNote: $closingNote)
            } else {
                StartView(book: book, monochrome: false, showReleaseConfirmation: $showReleaseConfirmation)
            }
        }
        .background(AppPalette.surface)
        .foregroundStyle(AppPalette.ink)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 14)
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

private struct KindleSurface: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook
    @Binding var showReleaseConfirmation: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "line.3.horizontal")
                Spacer()
                Text("Ещё пять").font(.system(.title3, design: .serif, weight: .semibold))
                Spacer()
                Text("6 сентября").font(.caption)
            }
            .padding(.horizontal, 18)
            .frame(height: 66)
            .overlay(alignment: .bottom) { Rectangle().frame(height: 1) }

            if store.state.session.status == .ready {
                StartView(book: book, monochrome: true, showReleaseConfirmation: $showReleaseConfirmation)
            } else {
                KindleSessionView(book: book)
            }
        }
        .foregroundStyle(.black)
        .background(Color(red: 0.97, green: 0.97, blue: 0.95))
        .overlay { Rectangle().stroke(.black, lineWidth: 2) }
    }
}

private struct KindleSessionView: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(store.state.session.status == .complete ? "Пять страниц прочитаны" : "Читаем без спешки")
                .font(.system(size: 36, design: .serif))
            Text("\(store.state.session.pagesCompleted) из \(store.state.session.goalPages) страниц")
                .font(.system(size: 20, weight: .semibold, design: .serif))
            ProgressView(value: Double(store.state.session.pagesCompleted), total: Double(store.state.session.goalPages))
                .tint(.black)

            if store.state.session.status == .complete {
                Text("Добавь заметку и закончи сеанс на Mac.")
                    .font(.system(size: 18, design: .serif))
            } else {
                Button("Следующая страница") { store.nextPage() }
                    .buttonStyle(.bordered)
                    .tint(.black)
            }

            Spacer()
            Text("\(book.title) · \(book.chapter)")
                .font(.system(size: 14, design: .serif))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct StartView: View {
    @EnvironmentObject private var store: ReadingStore
    let book: ActiveBook
    let monochrome: Bool
    @Binding var showReleaseConfirmation: Bool

    var body: some View {
        VStack(spacing: monochrome ? 22 : 28) {
            Text("Когда продолжим?")
                .font(.system(size: monochrome ? 38 : 56, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity, alignment: monochrome ? .leading : .center)

            HStack(spacing: monochrome ? 8 : 16) {
                ForEach(ReadingMoment.allCases) { moment in
                    MomentButton(moment: moment, selected: store.state.session.selectedMoment == moment, monochrome: monochrome) {
                        store.select(moment)
                    }
                }
            }

            Label("Только 5 страниц — можно остановиться раньше", systemImage: "book")
                .font(monochrome ? .system(.caption, design: .serif) : .subheadline)
                .frame(maxWidth: .infinity, alignment: monochrome ? .leading : .center)
                .padding(.vertical, monochrome ? 14 : 0)
                .overlay(alignment: .bottom) { if monochrome { Rectangle().frame(height: 1) } }

            HStack(alignment: .bottom, spacing: 34) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(book.author.uppercased()).font(.system(size: 11, design: .serif)).tracking(1)
                    Text(book.title).font(.system(size: monochrome ? 30 : 40, design: .serif))
                    Text("Продолжить чтение с:").font(.system(size: 12, design: .serif)).padding(.top, 8)
                    Text("\(book.chapter) · страница \(book.page)").font(.system(size: 14, weight: .semibold, design: .serif))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Заметка для себя:").font(.caption).foregroundStyle(monochrome ? .primary : .secondary)
                    Text(book.resumeNote).font(.system(size: monochrome ? 23 : 27, design: .serif)).italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if monochrome {
                startButton
                    .buttonStyle(.bordered)
                    .tint(.black)
            } else {
                startButton
                    .buttonStyle(.borderedProminent)
                    .tint(AppPalette.accent)
            }

            Button("Отпустить книгу") { showReleaseConfirmation = true }
                .buttonStyle(.plain)
                .fontWeight(.semibold)

            Label(store.connection.rawValue, systemImage: store.connection == .connected ? "checkmark.circle" : "wifi.slash")
                .font(.caption)
                .foregroundStyle(monochrome ? .primary : .secondary)
        }
        .padding(monochrome ? 22 : 42)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var startButton: some View {
        Button { store.startSession() } label: {
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
    let monochrome: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: moment.symbol).font(.system(size: monochrome ? 28 : 36, weight: .light))
                Text(moment.title).font(.system(size: monochrome ? 12 : 15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: monochrome ? 104 : 126)
            .background(selected ? (monochrome ? Color.black.opacity(0.08) : Color.blue.opacity(0.05)) : Color.clear)
            .overlay { RoundedRectangle(cornerRadius: monochrome ? 2 : 10).stroke(selected ? (monochrome ? Color.black : Color.blue) : Color.secondary.opacity(0.45), lineWidth: selected ? 2 : 1) }
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
                Button("Следующая страница") { store.nextPage() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppPalette.accent)
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
