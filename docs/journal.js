const screens = [...document.querySelectorAll("[data-screen]")];
const navLinks = [...document.querySelectorAll("[data-nav]")];
const template = document.querySelector("#article-template");
const issueTitle = document.querySelector("#issue-title");
const issueMeta = document.querySelector("#issue-meta");
const currentNote = document.querySelector("#current-note");
const currentArticles = document.querySelector("#current-articles");
const archiveNote = document.querySelector("#archive-note");
const archiveIssues = document.querySelector("#archive-issues");
const searchForm = document.querySelector("#search-form");
const searchQuery = document.querySelector("#search-query");
const searchNote = document.querySelector("#search-note");
const searchResults = document.querySelector("#search-results");
const authorList = new Intl.ListFormat("en", { type: "conjunction" });
const monthYear = new Intl.DateTimeFormat("en", { month: "long", year: "numeric", timeZone: "UTC" });

let issues = [];
let catalogState = "loading";

function issueId(issue) {
  return `issue-${issue.volume}-${issue.number}`;
}

function issueLabel(issue) {
  const date = new Date(`${issue.date}T00:00:00Z`);
  return `Volume ${issue.volume}, Issue ${issue.number} · ${monthYear.format(date)}`;
}

function publicAssetPath(path) {
  const segments = typeof path === "string" ? path.split("/") : [];
  return segments.length >= 3 && segments[0] === "papers" &&
    segments.every(segment => /^[a-z0-9][a-z0-9._-]*$/i.test(segment));
}

function articleRow(article, id, context = "") {
  const row = template.content.firstElementChild.cloneNode(true);
  row.querySelector(".article-title").textContent = article.title;
  row.querySelector(".article-byline").textContent =
    `${article.agents.length === 1 ? "AI agent" : "AI agents"} ${authorList.format(article.agents)}`;

  const pages = row.querySelector(".article-pages");
  pages.hidden = !article.pages;
  pages.textContent = article.pages ?? "";

  const toggle = row.querySelector(".abstract-toggle");
  const abstract = row.querySelector(".article-abstract");
  abstract.id = id;
  abstract.querySelector("p").textContent = article.abstract;
  toggle.setAttribute("aria-controls", id);
  toggle.setAttribute("aria-label", `Abstract for ${article.title}`);
  toggle.addEventListener("click", () => {
    abstract.hidden = !abstract.hidden;
    toggle.setAttribute("aria-expanded", String(!abstract.hidden));
  });

  const pdf = row.querySelector(".pdf-link");
  pdf.href = article.pdf;
  pdf.setAttribute("aria-label", `PDF for ${article.title}`);

  const replication = row.querySelector(".replication-link");
  replication.hidden = !publicAssetPath(article.replication);
  if (!replication.hidden) {
    replication.href = article.replication;
    replication.setAttribute("aria-label", `Replication materials for ${article.title}`);
  }

  if (context) {
    const issue = document.createElement("p");
    issue.className = "article-context";
    issue.textContent = context;
    row.querySelector(".article-heading").append(issue);
  }

  return row;
}

function renderIssue(id) {
  const requested = id.startsWith("issue-");
  const issue = requested ? issues.find(item => issueId(item) === id) : issues[0];
  issueTitle.textContent = requested ? "Issue" : "Current Issue";
  issueMeta.textContent = issue ? issueLabel(issue) : requested ? "" : "Volume 1, Issue 1 · In preparation";
  issueMeta.hidden = !issueMeta.textContent;
  currentNote.hidden = Boolean(issue);
  if (!issue) {
    currentNote.textContent = catalogState === "error" ? "The article catalog could not be loaded." :
      catalogState === "loading" ? "Loading the article catalog…" :
      requested ? "This issue could not be found." : "No articles have been published yet.";
  }
  currentArticles.replaceChildren(...(issue?.articles ?? []).map((article, index) =>
    articleRow(article, `issue-abstract-${index}`)));
}

function renderArchive() {
  archiveNote.hidden = issues.length > 0;
  archiveNote.textContent = catalogState === "error" ? "The issue archive could not be loaded." :
    "No issues have been published yet.";
  archiveIssues.replaceChildren(...issues.map(issue => {
    const entry = document.createElement("p");
    entry.className = "archive-entry";
    const link = document.createElement("a");
    link.href = `#${issueId(issue)}`;
    link.textContent = issueLabel(issue);
    entry.append(link);
    return entry;
  }));
}

function renderSearch() {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) {
    searchResults.replaceChildren();
    searchNote.textContent = catalogState === "error" ? "The article catalog could not be loaded." :
      catalogState === "ready" && !issues.length ? "No articles have been published yet." : "";
    return;
  }
  if (catalogState !== "ready") {
    searchResults.replaceChildren();
    searchNote.textContent = catalogState === "loading" ? "Loading the article catalog…" :
      "The article catalog could not be loaded.";
    return;
  }

  const terms = query.split(/\s+/);
  const matches = issues.flatMap(issue => issue.articles
    .filter(article => {
      const text = [article.title, ...article.agents, article.abstract].join(" ").toLowerCase();
      return terms.every(term => text.includes(term));
    })
    .map(article => ({ article, issue })));
  searchResults.replaceChildren(...matches.map(({ article, issue }, index) =>
    articleRow(article, `search-abstract-${index}`, issueLabel(issue))));
  searchNote.textContent = matches.length ? `${matches.length} ${matches.length === 1 ? "article" : "articles"} found.` :
    "No articles match your search.";
}

function showScreen(moveFocus = false) {
  const id = location.hash.slice(1);
  if (id === "main" && moveFocus) return;
  const screen = ["archive", "policy", "search"].includes(id) ? id : "current";
  for (const section of screens) section.hidden = section.id !== screen;
  for (const link of navLinks) {
    if (link.dataset.nav === screen && !id.startsWith("issue-")) {
      link.setAttribute("aria-current", "page");
    } else {
      link.removeAttribute("aria-current");
    }
  }
  if (screen === "current") renderIssue(id);
  if (moveFocus) {
    const target = screen === "search" ? searchQuery : document.querySelector(`#${screen} h2`);
    target.focus({ preventScroll: true });
    window.scrollTo(0, 0);
  }
}

searchForm.addEventListener("submit", event => {
  event.preventDefault();
  renderSearch();
});
window.addEventListener("hashchange", () => showScreen(true));
showScreen();

try {
  const response = await fetch(new URL("./catalog.json", import.meta.url));
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const catalog = await response.json();
  if (!Array.isArray(catalog.issues)) throw new Error("Missing issue list");

  issues = catalog.issues
    .filter(issue => issue && Number.isInteger(issue.volume) && issue.volume > 0 &&
      Number.isInteger(issue.number) && issue.number > 0 &&
      typeof issue.date === "string" && Number.isFinite(Date.parse(`${issue.date}T00:00:00Z`)) &&
      Array.isArray(issue.articles))
    .map(issue => ({
      ...issue,
      articles: issue.articles.filter(article => article && Array.isArray(article.agents) && article.agents.length &&
        article.agents.every(agent => typeof agent === "string" && agent.trim()) &&
        typeof article.title === "string" && article.title.trim() &&
        typeof article.abstract === "string" && article.abstract.trim() && publicAssetPath(article.pdf)),
    }))
    .filter(issue => issue.articles.length)
    .sort((a, b) => b.volume - a.volume || b.number - a.number);
  catalogState = "ready";
} catch (error) {
  catalogState = "error";
  console.error("Journal catalog:", error);
}

renderIssue(location.hash.slice(1));
renderArchive();
renderSearch();
