# Statistical Analysis of Attachment Time in an Ingestible Drug Delivery Robot

A two-way factorial study of how orifice diameter and vacuum volume affect the
attachment time of an ingestible drug delivery robot, analysed with two-way
ANOVA, effect sizes, assumption checks, and post-hoc testing.

**Domain:** experimental statistics, design optimisation, biomedical device performance
**Tool:** Minitab 21
**Design:** 3x2 full factorial (three orifice diameters, two vacuum volumes), three replicates per condition

**Competencies demonstrated:** experimental design, two-way ANOVA, effect-size reporting (partial eta-squared), parametric assumption testing, post-hoc analysis (Tukey HSD), critical evaluation of method choice

---

## Overview

An ingestible drug delivery robot must stay attached to the gut wall long enough
to deliver its payload, and two design parameters govern how long it holds:
orifice diameter and vacuum volume. This study tests how each affects attachment
time, and whether they interact, in order to identify the settings that maximise
attachment.

Attachment time was measured across a 3x2 full factorial design: three orifice
diameters (4, 5, 6 mm) crossed with two vacuum volumes (0.4 and 0.6 mm cubed),
with three replicates per condition. The analysis uses a two-way ANOVA as the
primary method, supported by formal assumption checks, effect-size estimation,
and a post-hoc test to locate the specific differences.

The full report is available as a PDF:
[Statistical_Analysis_Drug_Delivery_Robot.pdf](Statistical_Analysis_Drug_Delivery_Robot.pdf).

## Method

- **Design:** 3x2 full factorial, both factors treated as fixed effects, with the interaction term included.
- **Primary test:** two-way ANOVA at a 0.05 significance level, testing both main effects and their interaction within a single model to avoid the inflated false-positive risk of separate one-way tests.
- **Assumption checks:** residual normality (Ryan-Joiner), equal variance, and independence, all checked formally on the model residuals before interpreting the ANOVA.
- **Effect size:** partial eta-squared reported alongside each F-test, to quantify how much of the variation each factor explains rather than reporting significance alone.
- **Post-hoc:** Tukey HSD on the significant factor, to identify which specific levels differ.

## Results

- **Orifice diameter** had a highly significant and very large effect on attachment time (F(2, 12) = 84.59, p < 0.001, partial eta-squared = 0.934). The 6 mm diameter produced the longest mean attachment time (39.07 hours), significantly outperforming both smaller diameters.
- **Vacuum volume** also had a significant effect, with the larger 0.6 mm cubed volume producing longer attachment.
- **No interaction** between the two factors (p = 0.894): each parameter improves attachment time independently.

<img src="figures/interaction-plot.png" width="560" alt="Interaction plot of attachment time by diameter and vacuum volume">

*Interaction plot for mean attachment time by orifice diameter and vacuum volume. The approximately parallel lines confirm no interaction: diameter and vacuum volume each improve attachment time independently.*

The Tukey HSD post-hoc test placed the 6 mm diameter in its own group,
confirming it as significantly longer-attaching than the 4 mm and 5 mm diameters.

## Engineering judgment

Two features distinguish the analysis:

- **Effect sizes, not just p-values.** Reporting partial eta-squared (0.934 for
  diameter) quantifies how much of the variation the factor actually explains,
  which a p-value alone does not convey. This matters because statistical
  significance and practical importance are not the same thing.
- **Honest critique of method choice.** The report notes that the Ryan-Joiner
  test was used for normality because it is the option Minitab provides for
  residuals, while acknowledging that Shapiro-Wilk would have been preferable,
  being more widely cited in biomedical research and slightly more powerful at
  small sample sizes. Recognising where the tool constrained the method, and
  naming the better alternative, is the kind of transparency expected in
  professional analysis.

## Limitations

The report states its limitations directly: a small sample (three per condition)
that reduces statistical power, and the absence of a formal power analysis, which
leaves the risk of a Type II error on smaller effects unquantified. A more
rigorous design would increase replication and run a power analysis to set the
sample size in advance.

## Conclusion

Within the range tested, a 6 mm orifice diameter with a 0.6 mm cubed vacuum
volume produced the longest attachment time, with diameter the dominant factor
(explaining 93% of the variation) and no interaction between the two parameters.
The two factors can therefore be optimised independently. The analysis
demonstrates a complete, assumption-checked factorial workflow: descriptive
statistics, formal assumption testing, two-way ANOVA with effect sizes, and
post-hoc comparison, applied to a real biomedical device design question.
