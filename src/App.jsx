import { useMemo, useState } from "react";
import {
  BookOpen,
  CheckCircle,
  Clock,
  List,
  Moon,
  SunHorizon,
  X,
} from "@phosphor-icons/react";
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/source-serif-4/400.css";
import "@fontsource/source-serif-4/600.css";

const moments = [
  { id: "now", label: "Сейчас", Icon: Clock, helper: "Начнём без подготовки" },
  { id: "evening", label: "Вечером", Icon: Moon, helper: "Напомним в 20:30" },
  { id: "morning", label: "Завтра утром", Icon: SunHorizon, helper: "Напомним в 08:30" },
];

const readingParagraphs = [
  "Когда вошли, Анна уже сидела у окна. Она не обернулась сразу, словно хотела дослушать, что говорил дождь по стеклу.",
  "В комнате было тихо. Только часы на камине отсчитывали секунды, и каждая из них казалась началом разговора, которого оба боялись.",
  "— Я думала, вы не придёте, — сказала она наконец и закрыла книгу, оставив палец между страницами.",
];

function MomentPicker({ selected, onSelect, monochrome = false }) {
  return (
    <div className={`moment-grid ${monochrome ? "moment-grid--mono" : ""}`} role="radiogroup" aria-label="Когда продолжить чтение">
      {moments.map(({ id, label, Icon, helper }) => (
        <button
          className={`moment ${selected === id ? "is-selected" : ""}`}
          key={id}
          onClick={() => onSelect(id)}
          role="radio"
          aria-checked={selected === id}
          title={helper}
        >
          <span className="radio-dot" aria-hidden="true" />
          <Icon size={monochrome ? 34 : 44} weight="light" aria-hidden="true" />
          <span>{label}</span>
        </button>
      ))}
    </div>
  );
}

function BookDetails({ compact = false }) {
  return (
    <section className={`book-details ${compact ? "book-details--compact" : ""}`}>
      <div>
        <p className="eyebrow">Лев Толстой</p>
        <h2>Анна Каренина</h2>
        <div className="ornament" aria-hidden="true"><span /> <i /> <span /></div>
        <p className="resume-label">Продолжить чтение с:</p>
        <p className="resume-position">Часть II, глава 8 · страница 163</p>
      </div>
      <blockquote>
        <span>Заметка для себя:</span>
        Начни с разговора<br />у окна
      </blockquote>
    </section>
  );
}

function ReadingView({ onClose, pagesRead, onPage }) {
  return (
    <section className="reading-view" aria-label="Режим чтения">
      <header>
        <button className="icon-button" onClick={onClose} aria-label="Закрыть чтение"><X size={22} /></button>
        <div>
          <p>Анна Каренина</p>
          <span>Часть II · глава 8</span>
        </div>
        <p className="reading-count">{pagesRead} из 5</p>
      </header>
      <article>
        <p className="chapter-kicker">Глава VIII</p>
        <h2>Разговор у окна</h2>
        {readingParagraphs.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}
      </article>
      <footer>
        <div className="page-progress" aria-label={`Прочитано ${pagesRead} из 5 страниц`}>
          {Array.from({ length: 5 }, (_, index) => <span className={index < pagesRead ? "is-read" : ""} key={index} />)}
        </div>
        <button className="primary-button" onClick={onPage} disabled={pagesRead === 5}>
          {pagesRead === 5 ? <><CheckCircle size={23} weight="fill" /> Сеанс завершён</> : <>Следующая страница</>}
        </button>
      </footer>
    </section>
  );
}

export function App() {
  const [selected, setSelected] = useState("now");
  const [reading, setReading] = useState(false);
  const [pagesRead, setPagesRead] = useState(1);
  const [releaseOpen, setReleaseOpen] = useState(false);
  const [released, setReleased] = useState(false);

  const selectedMoment = useMemo(() => moments.find((item) => item.id === selected), [selected]);

  const startReading = () => {
    if (selected !== "now") return;
    setReading(true);
  };

  if (released) {
    return (
      <main className="empty-state">
        <div>
          <BookOpen size={48} weight="light" />
          <h1>Место для следующей книги</h1>
          <p>Ты не бросил книгу — ты освободил внимание. Когда будешь готов, выбери одну новую.</p>
          <button className="primary-button" onClick={() => setReleased(false)}>Вернуть «Анну Каренину»</button>
        </div>
      </main>
    );
  }

  return (
    <main className="app-shell">
      <section className="mac-surface">
        {reading ? (
          <ReadingView onClose={() => setReading(false)} pagesRead={pagesRead} onPage={() => setPagesRead((page) => Math.min(5, page + 1))} />
        ) : (
          <>
            <header className="topbar">
              <button className="icon-button menu-button" aria-label="Открыть меню"><List size={22} /></button>
              <strong>Дальше</strong>
              <time>6 сентября 2026 г.</time>
            </header>
            <div className="mac-content">
              <section className="ritual">
                <h1>Когда продолжим?</h1>
                <MomentPicker selected={selected} onSelect={setSelected} />
                <p className="tiny-promise"><BookOpen size={25} weight="light" /> Только 5 страниц — можно остановиться раньше</p>
              </section>
              <BookDetails />
              <div className="actions">
                <button className="primary-button" onClick={startReading} disabled={selected !== "now"}>
                  <BookOpen size={25} weight="light" />
                  {selected === "now" ? "Начать 5 страниц" : `Запланировано: ${selectedMoment.label.toLowerCase()}`}
                </button>
                <button className="release-button" onClick={() => setReleaseOpen(true)}>Отпустить книгу</button>
              </div>
              <p className="sync-status"><CheckCircle size={19} weight="regular" /> Синхронизировано</p>
            </div>
          </>
        )}
      </section>

      <aside className="kindle-surface" aria-label="Интерфейс Kindle Scribe">
        <header className="kindle-topbar">
          <List size={21} />
          <strong>Дальше</strong>
          <time>6 сентября</time>
        </header>
        <div className="kindle-content">
          <h1>Когда продолжим?</h1>
          <MomentPicker selected={selected} onSelect={setSelected} monochrome />
          <p className="tiny-promise"><BookOpen size={22} weight="light" /> Только 5 страниц — можно остановиться раньше</p>
          <BookDetails compact />
          <button className="kindle-primary" onClick={startReading} disabled={selected !== "now"}>
            <BookOpen size={22} /> {selected === "now" ? "Начать 5 страниц" : selectedMoment.label}
          </button>
          <button className="kindle-release" onClick={() => setReleaseOpen(true)}>Отпустить книгу</button>
          <p className="sync-status"><CheckCircle size={18} /> Синхронизировано</p>
        </div>
      </aside>

      {releaseOpen && (
        <div className="modal-backdrop" role="presentation" onMouseDown={() => setReleaseOpen(false)}>
          <section className="release-dialog" role="dialog" aria-modal="true" aria-labelledby="release-title" onMouseDown={(event) => event.stopPropagation()}>
            <button className="icon-button dialog-close" onClick={() => setReleaseOpen(false)} aria-label="Закрыть"><X size={20} /></button>
            <p className="eyebrow">Без чувства вины</p>
            <h2 id="release-title">Отпустить эту книгу?</h2>
            <p>Она исчезнет с главного экрана, а прогресс и заметка сохранятся. К ней всегда можно вернуться.</p>
            <div>
              <button className="secondary-button" onClick={() => setReleaseOpen(false)}>Продолжить читать</button>
              <button className="primary-button danger-neutral" onClick={() => setReleased(true)}>Отпустить книгу</button>
            </div>
          </section>
        </div>
      )}
    </main>
  );
}
