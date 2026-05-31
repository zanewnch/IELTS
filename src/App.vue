<script setup lang="ts">
import {
  BookOpen,
  CheckCircle2,
  Filter,
  Flame,
  LayoutGrid,
  RefreshCw,
  Search,
  Sparkles,
} from "@lucide/vue";
import { computed, onMounted, ref } from "vue";
import type { MaterialsPayload, SpeakingTopic } from "./types";

const payload = ref<MaterialsPayload | null>(null);
const loading = ref(true);
const error = ref("");
const query = ref("");
const partFilter = ref("all");
const categoryFilter = ref("all");
const priorityFilter = ref("all");
const newOnly = ref(false);
const selectedTopicId = ref("");

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

onMounted(loadMaterials);

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
</script>

<template>
  <main class="app-shell">
    <section class="topbar">
      <div>
        <p class="eyebrow">IELTS Speaking</p>
        <h1>Study Materials</h1>
      </div>
      <button class="icon-button" type="button" title="Reload materials" @click="loadMaterials">
        <RefreshCw :size="18" />
      </button>
    </section>

    <section v-if="loading" class="state-panel">
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
