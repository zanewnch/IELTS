export type Part = "part_1" | "part_2_3";

export interface SpeakingTopic {
  id: string;
  source: string;
  part: Part;
  part_label: string;
  category: string;
  category_label: string;
  categories: string[];
  topic_name: string;
  question_count: number;
  sample_question_id: number | string | null;
  sample_question: string;
  recent_exam_count: number;
  learner_count: string;
  time_tag: string;
  is_new: boolean;
  source_categories: string[];
  priority: string;
}

export interface MaterialsPayload {
  summary: {
    generated_at: string;
    source: {
      name?: string;
      site_url?: string;
      usage_note?: string;
    };
    counts: {
      topics: number;
      new_topics: number;
      part_1: number;
      part_2_3: number;
    };
    by_category: Record<string, number>;
    by_priority: Record<string, number>;
  };
  topics: SpeakingTopic[];
}
