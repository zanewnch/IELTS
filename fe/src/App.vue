<script setup lang="ts">
import {
  BookOpen,
  CheckCircle2,
  Compass,
  FilePenLine,
  Filter,
  Flame,
  LayoutGrid,
  ListPlus,
  Moon,
  RefreshCw,
  Search,
  Settings,
  Sparkles,
  Sun,
} from "@lucide/vue";
import { computed, onMounted, ref, watch } from "vue";
import type { MaterialsPayload, SpeakingTopic } from "./types";

type StudyDirection = {
  id: number;
  title: string;
  focus: string;
  status: "planning" | "active" | "done";
};

type AppTheme = "dark" | "bright";

const payload = ref<MaterialsPayload | null>(null);
const loading = ref(true);
const error = ref("");
const query = ref("");
const partFilter = ref("all");
const categoryFilter = ref("all");
const priorityFilter = ref("all");
const newOnly = ref(false);
const selectedTopicId = ref("");
const activeView = ref<"materials" | "direction" | "settings">("materials");
const appTheme = ref<AppTheme>("dark");
const directionNotes = ref("");
const newDirectionTitle = ref("");
const newDirectionFocus = ref("");
const studyDirections = ref<StudyDirection[]>([
  {
    id: 1,
    title: "建立 IELTS Speaking 自學節奏",
    focus: "每天固定選 1 個題目，先寫關鍵字，再錄音回答，最後補強句型和詞彙。",
    status: "active",
  },
  {
    id: 2,
    title: "整理常用答案素材",
    focus: "把人物、地點、經驗、喜好、困難、改變等素材做成可重複使用的答案庫。",
    status: "planning",
  },
  {
    id: 3,
    title: "追蹤弱點",
    focus: "每次練習後只記 1 到 2 個最需要改的地方，例如停頓、時態、連接詞或發音。",
    status: "planning",
  },
  {
    id: 4,
    title: "確認材料是否貼近真實雅思",
    focus: "擔心自己找的 material 不符合真實雅思考題時，就直接練完整模擬試題。做完後對照題型、難度、時間壓力和回答品質，就能知道目前材料是否值得繼續使用。",
    status: "planning",
  },
]);

const priorityOrder = [
  "New and high frequency",
  "High frequency",
  "New topic",
  "Regular practice",
];

async function loadMaterials() {
  loading.value = true;
  error.value = "";
  try {
    const response = await fetch("/data/speaking-topics.json", {
      cache: "no-store",
    });
    if (!response.ok) {
      throw new Error(`Failed to load materials: ${response.status}`);
    }
    payload.value = (await response.json()) as MaterialsPayload;
    selectedTopicId.value = payload.value.topics[0]?.id ?? "";
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Failed to load materials.";
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  restoreTheme();
  loadMaterials();
  restoreDirectionDraft();
});

watch(
  appTheme,
  () => {
    applyTheme();
    localStorage.setItem("ielts-app-theme", appTheme.value);
  },
  { flush: "post" },
);

watch(
  [directionNotes, studyDirections],
  () => {
    localStorage.setItem("ielts-design-direction-notes", directionNotes.value);
    localStorage.setItem("ielts-design-directions", JSON.stringify(studyDirections.value));
  },
  { deep: true },
);

const topics = computed(() => payload.value?.topics ?? []);

const categories = computed(() => {
  const labels = new Map<string, string>();
  topics.value.forEach((topic) => labels.set(topic.category, topic.category_label));
  return Array.from(labels.entries()).sort((a, b) => a[1].localeCompare(b[1]));
});

const priorities = computed(() => {
  const seen = new Set(topics.value.map((topic) => topic.priority));
  return priorityOrder.filter((priority) => seen.has(priority));
});

const filteredTopics = computed(() => {
  const needle = query.value.trim().toLowerCase();
  return topics.value.filter((topic) => {
    const matchesQuery =
      !needle ||
      topic.topic_name.toLowerCase().includes(needle) ||
      topic.sample_question.toLowerCase().includes(needle) ||
      topic.category_label.toLowerCase().includes(needle);
    const matchesPart = partFilter.value === "all" || topic.part === partFilter.value;
    const matchesCategory =
      categoryFilter.value === "all" || topic.category === categoryFilter.value;
    const matchesPriority =
      priorityFilter.value === "all" || topic.priority === priorityFilter.value;
    const matchesNew = !newOnly.value || topic.is_new;
    return matchesQuery && matchesPart && matchesCategory && matchesPriority && matchesNew;
  });
});

const selectedTopic = computed<SpeakingTopic | null>(() => {
  const found = filteredTopics.value.find((topic) => topic.id === selectedTopicId.value);
  return found ?? filteredTopics.value[0] ?? null;
});

const partOneCount = computed(() => filteredTopics.value.filter((topic) => topic.part === "part_1").length);
const partTwoCount = computed(() => filteredTopics.value.filter((topic) => topic.part === "part_2_3").length);
const newCount = computed(() => filteredTopics.value.filter((topic) => topic.is_new).length);
const highFrequencyCount = computed(
  () => filteredTopics.value.filter((topic) => topic.recent_exam_count >= 700).length,
);

function selectTopic(topic: SpeakingTopic) {
  selectedTopicId.value = topic.id;
}

function resetFilters() {
  query.value = "";
  partFilter.value = "all";
  categoryFilter.value = "all";
  priorityFilter.value = "all";
  newOnly.value = false;
}

function partName(part: string) {
  return part === "part_1" ? "Part 1" : "Part 2/3";
}

function restoreTheme() {
  const savedTheme = localStorage.getItem("ielts-app-theme");
  appTheme.value = savedTheme === "bright" ? "bright" : "dark";
  applyTheme();
}

function applyTheme() {
  document.documentElement.dataset.theme = appTheme.value;
}

function restoreDirectionDraft() {
  directionNotes.value = localStorage.getItem("ielts-design-direction-notes") ?? "";
  const savedDirections = localStorage.getItem("ielts-design-directions");
  if (!savedDirections) {
    return;
  }
  try {
    const parsed = JSON.parse(savedDirections) as StudyDirection[];
    if (Array.isArray(parsed)) {
      studyDirections.value = parsed;
    }
  } catch {
    localStorage.removeItem("ielts-design-directions");
  }
}

function addDirection() {
  const title = newDirectionTitle.value.trim();
  const focus = newDirectionFocus.value.trim();
  if (!title && !focus) {
    return;
  }
  studyDirections.value.unshift({
    id: Date.now(),
    title: title || "未命名方向",
    focus: focus || "先記下想法，之後再補上具體練習方式。",
    status: "planning",
  });
  newDirectionTitle.value = "";
  newDirectionFocus.value = "";
}

function removeDirection(id: number) {
  studyDirections.value = studyDirections.value.filter((direction) => direction.id !== id);
}

function statusLabel(status: StudyDirection["status"]) {
  if (status === "active") {
    return "進行中";
  }
  if (status === "done") {
    return "已完成";
  }
  return "規劃中";
}
</script>

<template>
  <main class="app-shell">
    <section class="topbar">
      <div>
        <p class="eyebrow">IELTS Speaking</p>
        <h1>
          {{
            activeView === "materials"
              ? "Study Materials"
              : activeView === "direction"
                ? "設計方向"
                : "設定"
          }}
        </h1>
      </div>
      <div class="topbar-actions">
        <nav class="view-tabs" aria-label="Pages">
          <button
            :class="{ active: activeView === 'materials' }"
            type="button"
            @click="activeView = 'materials'"
          >
            題庫
          </button>
          <button
            :class="{ active: activeView === 'direction' }"
            type="button"
            @click="activeView = 'direction'"
          >
            設計方向
          </button>
          <button
            :class="{ active: activeView === 'settings' }"
            type="button"
            @click="activeView = 'settings'"
          >
            設定
          </button>
        </nav>
        <button
          v-if="activeView === 'materials'"
          class="icon-button"
          type="button"
          title="Reload materials"
          @click="loadMaterials"
        >
          <RefreshCw :size="18" />
        </button>
      </div>
    </section>

    <section v-if="activeView === 'settings'" class="settings-page" aria-label="設定">
      <section class="settings-hero">
        <div>
          <p class="eyebrow">Preferences</p>
          <h2>設定你的練習環境。</h2>
        </div>
        <Settings :size="34" />
      </section>

      <section class="settings-grid">
        <article class="settings-panel">
          <div class="panel-title">
            <Moon v-if="appTheme === 'dark'" :size="18" />
            <Sun v-else :size="18" />
            <h2>Theme</h2>
          </div>
          <p class="settings-copy">選擇你要的閱讀亮度。預設是 dark，適合長時間整理題目和自學紀錄。</p>
          <div class="theme-options" role="radiogroup" aria-label="Theme">
            <button
              class="theme-option dark-option"
              :class="{ active: appTheme === 'dark' }"
              type="button"
              role="radio"
              :aria-checked="appTheme === 'dark'"
              @click="appTheme = 'dark'"
            >
              <Moon :size="20" />
              <span>Dark</span>
            </button>
            <button
              class="theme-option bright-option"
              :class="{ active: appTheme === 'bright' }"
              type="button"
              role="radio"
              :aria-checked="appTheme === 'bright'"
              @click="appTheme = 'bright'"
            >
              <Sun :size="20" />
              <span>Bright</span>
            </button>
          </div>
        </article>

        <article class="settings-panel">
          <div class="panel-title">
            <FilePenLine :size="18" />
            <h2>Storage</h2>
          </div>
          <p class="settings-copy">
            設計方向、即時紀錄和 theme 都先存在這台電腦的瀏覽器。你可以一邊寫，我一邊幫你整理成可執行的自學方向。
          </p>
          <dl class="settings-stats">
            <div>
              <dt>Theme</dt>
              <dd>{{ appTheme === "dark" ? "Dark" : "Bright" }}</dd>
            </div>
            <div>
              <dt>Directions</dt>
              <dd>{{ studyDirections.length }}</dd>
            </div>
          </dl>
        </article>
      </section>
    </section>

    <section v-else-if="activeView === 'direction'" class="direction-page" aria-label="設計方向">
      <section class="direction-hero">
        <div>
          <p class="eyebrow">Self-study workspace</p>
          <h2>先把方向留下來，再慢慢把練習變成系統。</h2>
        </div>
        <Compass :size="34" />
      </section>

      <section class="direction-workspace">
        <article class="note-panel">
          <div class="panel-title">
            <FilePenLine :size="18" />
            <h2>即時紀錄</h2>
          </div>
          <textarea
            v-model="directionNotes"
            placeholder="你可以邊想邊寫：想練什麼、卡在哪裡、今天的目標、老師或網站給你的提醒..."
          />
          <p class="save-hint">已自動儲存在這台電腦的瀏覽器中。</p>
        </article>

        <aside class="direction-builder">
          <div class="panel-title">
            <ListPlus :size="18" />
            <h2>新增方向</h2>
          </div>
          <label class="control-group">
            <span>方向名稱</span>
            <input v-model="newDirectionTitle" type="text" placeholder="例如：Part 2 故事素材" />
          </label>
          <label class="control-group">
            <span>練習重點</span>
            <textarea
              v-model="newDirectionFocus"
              rows="4"
              placeholder="寫下你打算怎麼練、要觀察什麼、下一步要補什麼。"
            />
          </label>
          <button class="primary-button" type="button" @click="addDirection">加入方向</button>
        </aside>
      </section>

      <section class="direction-list" aria-label="Direction list">
        <article v-for="direction in studyDirections" :key="direction.id" class="direction-card">
          <div class="direction-card-heading">
            <div>
              <span class="status-pill" :class="direction.status">{{ statusLabel(direction.status) }}</span>
              <h3>{{ direction.title }}</h3>
            </div>
            <select v-model="direction.status" aria-label="Direction status">
              <option value="planning">規劃中</option>
              <option value="active">進行中</option>
              <option value="done">已完成</option>
            </select>
          </div>
          <p>{{ direction.focus }}</p>
          <button class="text-button" type="button" @click="removeDirection(direction.id)">刪除</button>
        </article>
      </section>
    </section>

    <section v-else-if="loading" class="state-panel">
      <BookOpen :size="24" />
      <p>Loading speaking topics...</p>
    </section>

    <section v-else-if="error" class="state-panel error-panel">
      <p>{{ error }}</p>
      <button type="button" @click="loadMaterials">Retry</button>
    </section>

    <template v-else-if="payload">
      <section class="summary-grid" aria-label="Material summary">
        <article class="metric-card">
          <LayoutGrid :size="20" />
          <div>
            <span>Total</span>
            <strong>{{ filteredTopics.length }}</strong>
          </div>
        </article>
        <article class="metric-card">
          <BookOpen :size="20" />
          <div>
            <span>Part 1</span>
            <strong>{{ partOneCount }}</strong>
          </div>
        </article>
        <article class="metric-card">
          <CheckCircle2 :size="20" />
          <div>
            <span>Part 2/3</span>
            <strong>{{ partTwoCount }}</strong>
          </div>
        </article>
        <article class="metric-card">
          <Sparkles :size="20" />
          <div>
            <span>New</span>
            <strong>{{ newCount }}</strong>
          </div>
        </article>
        <article class="metric-card">
          <Flame :size="20" />
          <div>
            <span>High freq</span>
            <strong>{{ highFrequencyCount }}</strong>
          </div>
        </article>
      </section>

      <section class="workspace">
        <aside class="filters-panel" aria-label="Filters">
          <div class="panel-title">
            <Filter :size="18" />
            <h2>Filters</h2>
          </div>

          <label class="search-box">
            <Search :size="18" />
            <input v-model="query" type="search" placeholder="Search topic or question" />
          </label>

          <div class="control-group">
            <span>Part</span>
            <div class="segmented">
              <button :class="{ active: partFilter === 'all' }" type="button" @click="partFilter = 'all'">
                All
              </button>
              <button :class="{ active: partFilter === 'part_1' }" type="button" @click="partFilter = 'part_1'">
                Part 1
              </button>
              <button :class="{ active: partFilter === 'part_2_3' }" type="button" @click="partFilter = 'part_2_3'">
                Part 2/3
              </button>
            </div>
          </div>

          <label class="control-group">
            <span>Category</span>
            <select v-model="categoryFilter">
              <option value="all">All categories</option>
              <option v-for="[value, label] in categories" :key="value" :value="value">
                {{ label }}
              </option>
            </select>
          </label>

          <label class="control-group">
            <span>Priority</span>
            <select v-model="priorityFilter">
              <option value="all">All priorities</option>
              <option v-for="priority in priorities" :key="priority" :value="priority">
                {{ priority }}
              </option>
            </select>
          </label>

          <label class="toggle-row">
            <input v-model="newOnly" type="checkbox" />
            <span>New topics only</span>
          </label>

          <button class="secondary-button" type="button" @click="resetFilters">Reset filters</button>
        </aside>

        <section class="topic-list" aria-label="Speaking topics">
          <button
            v-for="topic in filteredTopics"
            :key="topic.id"
            class="topic-row"
            :class="{ active: selectedTopic?.id === topic.id }"
            type="button"
            @click="selectTopic(topic)"
          >
            <span class="row-meta">{{ partName(topic.part) }} · {{ topic.category_label }}</span>
            <strong>{{ topic.topic_name }}</strong>
            <span class="row-question">{{ topic.sample_question }}</span>
            <span class="row-tags">
              <span v-if="topic.is_new" class="tag new-tag">New</span>
              <span class="tag">{{ topic.recent_exam_count }} recent</span>
              <span class="tag">{{ topic.question_count }} questions</span>
            </span>
          </button>

          <div v-if="filteredTopics.length === 0" class="empty-list">
            <p>No topics match the current filters.</p>
          </div>
        </section>

        <aside class="detail-panel" aria-label="Selected topic">
          <template v-if="selectedTopic">
            <div class="detail-heading">
              <span>{{ selectedTopic.part_label }} · {{ selectedTopic.category_label }}</span>
              <h2>{{ selectedTopic.topic_name }}</h2>
            </div>

            <div class="detail-tags">
              <span v-if="selectedTopic.is_new" class="tag new-tag">New topic</span>
              <span class="tag">{{ selectedTopic.priority }}</span>
              <span class="tag">{{ selectedTopic.time_tag || "No season tag" }}</span>
            </div>

            <section class="question-card">
              <span>Sample question</span>
              <p>{{ selectedTopic.sample_question }}</p>
            </section>

            <dl class="detail-stats">
              <div>
                <dt>Recent count</dt>
                <dd>{{ selectedTopic.recent_exam_count }}</dd>
              </div>
              <div>
                <dt>Question count</dt>
                <dd>{{ selectedTopic.question_count }}</dd>
              </div>
              <div>
                <dt>Learner count</dt>
                <dd>{{ selectedTopic.learner_count || "Unknown" }}</dd>
              </div>
              <div>
                <dt>Topic ID</dt>
                <dd>{{ selectedTopic.id }}</dd>
              </div>
            </dl>
          </template>
        </aside>
      </section>
    </template>
  </main>
</template>
