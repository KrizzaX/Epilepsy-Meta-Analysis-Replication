library(dplyr)
library(ggplot2)
library(tidyr)

fpr <- read.csv("Data/network_output/parsedFPR_info.csv")
training <- read.csv("Data/network_output/training_set.csv")

training <- training %>%
  rename(
    mouse_entrez = mouse_entrez....final_ortholog_table.entrez,
    human_entrez = human_entrez....final_ortholog_table.human_entrez
  )

mouse_training_genes <- unique(training$mouse_entrez)
human_training_genes <- unique(training$human_entrez)

human_df <- fpr %>%
  filter(!is.na(human_logFPR), is.finite(human_logFPR)) %>%
  mutate(
    Species = "Human",
    Score = human_logFPR,
    Training = ifelse(human_entrez %in% human_training_genes,
                      "Training", "Not Training")
  ) %>%
  select(Species, Score, Training)

mouse_df <- fpr %>%
  filter(!is.na(mouse_logFPR), is.finite(mouse_logFPR)) %>%
  mutate(
    Species = "Mouse",
    Score = mouse_logFPR,
    Training = ifelse(mouse_entrez %in% mouse_training_genes,
                      "Training", "Not Training")
  ) %>%
  select(Species, Score, Training)

df_long <- bind_rows(mouse_df, human_df)

df_long$Training <- factor(df_long$Training, levels = c("Not Training", "Training"))
df_long$Species <- factor(df_long$Species, levels = c("Mouse", "Human"))

counts <- df_long %>%
  group_by(Species, Training) %>%
  summarise(n = n(), .groups = "drop")

figure_2a <- ggplot(df_long, aes(x = Training, y = Score, fill = Training)) +
  geom_boxplot(outlier.size = 0.5) +
  facet_wrap(~Species) +
  geom_text(
    data = counts,
    aes(x = Training, y = 2.2, label = paste0("n = ", n)),
    inherit.aes = FALSE,
    size = 3.5
  ) +
  scale_fill_manual(values = c("Not Training" = "#D9D9D9",
                               "Training" = "#7a5072")) +
  theme_minimal() +
  labs(
    title = "Functional Score of Training Genes",
    x = "",
    y = "Functional Score"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )

figure_2a

ggsave("figure_2a_combined.png", figure_2a, width = 8, height = 4, dpi = 300)

