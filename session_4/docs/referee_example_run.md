# Referee subagent: example run (fallback for the block 32 demo)

Generated 2026-10-26 by running the instructions in `agents/referee.md` on `session_3/paper/course_paper.tex` (tables only; figures not visible to the agent). The agent was a general-purpose subagent given the referee file's body, not a registered `referee` agent, so the live demo may differ in wording. Report below is unedited model output. It has **not** been checked by me against the paper beyond what is noted here.

Things worth knowing before you show it:
- The paper is synthetic, built by `session_3/code/`. The report's concern 1 (abstract says "pre--post design", only a post-period cross-section is estimated) and concern 4 (150 "attended" vs. 94 completers) are the most substantive. Check them against `course_paper.tex` before presenting them as findings.
- "Numbers I could not match" correctly reports that several numbers in the prose appear only in figures, which the agent could not see. That is a limit of the setup, not necessarily an error in the paper.
- Concern 3 infers a base earnings level from the regression constant. That is an inference by the agent, not a reported number.

---

## Referee Report

**Claim as I understand it:** The paper claims that attending a five-session AI-assisted research workshop raised earnings measured two years later by about $16,384, relative to a waitlist comparison group.

**Recommendation:** reject

### Major concerns
1. **The design is not the one described, and it cannot support a causal "effect".** The abstract calls this a "simple pre--post design". Section 2 says pre-course earnings are observed for all 230 people. The only estimating equation (Section 5.1) is a single post-period cross-sectional OLS. Pre-course earnings appear nowhere: not in Table 1, not in the regression, and not as a difference-in-differences or change score. — *Where:* Abstract; Section 2 ("We observe pre-course and post-course earnings... for all 230 individuals"); Eq. (1); Table 2. — *Why it matters:* Without baseline earnings the estimate cannot separate the workshop from pre-existing earnings differences between groups. Those differences are the main threat in a non-randomized comparison. The prose, the abstract and the estimator describe three different designs.

2. **Assignment to the waitlist is not shown to be as-good-as-random, and the paper's own text undermines it.** The paper says the groups are "broadly comparable" and that "waitlist assignment was approximately random with respect to observable characteristics". That rests on two covariates, with no formal balance test. Attendees are 1.84 years younger. With SDs of about 7.5 to 8 and groups of 150 and 80, that gap is roughly 1.7 standard errors, so it is not negligible. Nothing in the draft says how spots were allocated (first-come, application, selection on motivation). The Discussion concedes that "unobserved motivation or institutional support may differ" but the paper still reports $16,384 as the effect. — *Where:* Section 2, paragraph after Table 1; Section 6. — *Why it matters:* If people who secured a spot differ in motivation, ambition or employer support, the coefficient is a selection effect. The draft gives no way to rule this out, and in the conventional reading it is the dominant rival explanation.

3. **The magnitude is implausible and the paper does not engage with it.** $16,384 is a very large effect for a five-session workshop. The paper gives no mean earnings for either group, so the reader cannot tell what percentage gain this is. The constant ($73,391) suggests a base around $70-90k, so the effect would be on the order of 20%. Table 1 reports no earnings at all, pre or post. — *Where:* Abstract; Table 1; Section 6 ("large relative to the cost of a five-session workshop"). — *Why it matters:* An effect this size from this intervention needs a mechanism and a sanity check against baseline. The cost comparison is also asserted with no cost figure.

4. **Attendance is defined at enrollment, but 37% of attendees did not finish, and this is never connected to the earnings estimate.** The regression has 150 "Attended" observations, yet Section 3 says only 94 completed all five sessions. The paper does not say whether the 56 who dropped out are coded as attended, and it does not say whether the estimate is an intent-to-treat effect or a dose effect. The attrition discussion mentions "selection effects" but does not link them to the regression. — *Where:* Section 3; Table 2 (N = 230); Abstract. — *Why it matters:* The treatment is heterogeneous (1 to 5 sessions). If dropouts are included, the coefficient understates the effect of completion. If they were excluded, N would not be 230. Either way, the interpretation of "attendance" is unclear.

5. **Waitlist contamination and the meaning of the control group.** Waitlisted individuals plausibly attended a later cohort, or learned the tools elsewhere, within the two-year window. The paper does not say whether they ever took the course. — *Where:* Section 1 ("a natural comparison group"); Section 2. — *Why it matters:* If controls were treated before the outcome was measured, the estimate is biased toward zero, or the contrast is "early versus late" rather than "treated versus untreated". Conversely, a waitlist that includes people who lost interest and withdrew would be selected on lower motivation.

6. **The covariate set is thin, and the variable that matters most for post-course earnings is missing.** Age and experience are the only controls. The model R² is 0.10. Pre-course earnings, field, sector, institution and gender are not controlled for. Age (+$310/year) and experience (−$270/year, insignificant) are likely highly collinear. The statement that experience "shows no statistically significant relationship" is correct but uninformative given that collinearity. — *Where:* Table 2; Section 5.1. — *Why it matters:* The treatment coefficient is identified only under conditional independence given two weak controls. The attended group's lower age and experience also work against it in this model, so the sign of the omitted-variable bias is not obvious from the text.

7. **The title and framing do not match the sample or the outcome.** The title says "Early-Career Earnings", but Section 1 describes participants "ranging from doctoral students to mid-career researchers". Mean experience of about 10 years and mean age of 34 to 36 are not obviously early-career. The Conclusion then says the paper "demonstrates a complete research workflow", which contradicts the Abstract's framing of an effect estimate. — *Where:* Title; Section 1; Section 7. — *Why it matters:* The paper presents itself as an evaluation of an intervention in some places and as a workflow demonstration in others. A reader cannot tell which claim is being defended.

### Minor concerns
1. The satisfaction section (Section 4) is unrelated to the identification of the earnings effect. The paper does acknowledge survivorship bias, but it still interprets the increase as the course having "built value as it progressed". The caveat and the interpretation sit side by side without being reconciled. — *Where:* Section 4.
2. "A steady increase" from 7.5 to 8.7 is described from the figure only. No per-session values or N per session are reported, and the shaded SD band is not tied to any number in the text. — *Where:* Section 4, Figure 3 caption.
3. The attrition rates (5% between Sessions 1 and 2; 15% between Session 4 and completion) appear only in prose and cannot be checked without per-session counts. No table gives enrollment by session. — *Where:* Section 3.
4. The explanation of attrition ("increasing technical difficulty in later sessions") is speculation. Nothing in the data distinguishes it from fatigue or scheduling. The paper does flag this, so this is minor. — *Where:* Section 3.
5. The standard errors are not described. The note says "Standard errors in parentheses" but does not say whether they are heteroskedasticity-robust. The groups have unequal size (150 vs 80). — *Where:* Table 2 note.
6. The Discussion says the R² of 0.10 "leaves room for omitted variable bias". A low R² is not itself evidence of bias, and a high R² would not rule it out. — *Where:* Section 6.
7. "Significant at the 0.1% level" is a loose phrasing of p<0.001. — *Where:* Section 5.1.
8. Table 1 gives no earnings or satisfaction rows and no test of differences. — *Where:* Table 1.
9. The synthetic-data caveat appears in the abstract and discussion, but the Introduction ("Participants ranged from doctoral students to mid-career researchers across economics, statistics, and computational fields") reads as real data without qualification. — *Where:* Section 1.

### Numbers I could not match
- "Attendees are slightly younger on average (34.3 vs. 36.2 years)" — Table 1 — Matches: 34.34 and 36.18.
- "marginally less professional experience (10.0 vs. 10.8 years)" — Table 1 — Matches: 9.96 and 10.84.
- "150 who attended... 80 who were placed on a waitlist", "230 individuals" — Table 1 (N row), Table 2 (Observations) — Matches.
- "approximately $16,384", "significant at the 0.1% level" — Table 2 — Matches: 16384.42, three stars.
- "Age... $310 per year, p<0.01" — Table 2 — Matches: 310.03 with two stars.
- "years of experience shows no statistically significant relationship" — Table 2 — Matches: −269.67 (SE 251.17), no stars.
- "roughly 10% of the variation" and "R² of 0.10" — Table 2 — Matches: 0.1046.
- "94 completed all five sessions --- a cumulative attrition rate of 37%" — no table — 56/150 = 37.3%, arithmetically consistent, but 94 is not in any table. It can only be checked against Figure 1, which I cannot see.
- "5% between Sessions 1 and 2, rising to 15% between Session 4 and course completion" — no table — Cannot be located in any table or caption.
- "Mean satisfaction rose from 7.5 in Session 1 to 8.7 in the final evaluation" — no table — Cannot be located in any table or caption.
- "The attended group shows both a higher median and a higher mean" — no table — Not in any table. Reported group means or medians are absent.
- "The estimated earnings effect of $16,384 is large relative to the cost" — no table — No cost figure is given anywhere.

### What I could not assess from the draft alone
- How waitlist assignment was made, and whether any waitlisted individuals attended before the outcome was measured.
- Whether dropouts are coded as "Attended" in the regression, and whether Table 2 estimates intent-to-treat or completion effects.
- Pre-course earnings for either group, and how earnings were measured (source, reference year, inflation adjustment, attrition from the earnings survey).
- What the figures show, since they are not available to me. This includes the enrollment counts, the session-by-session attrition, satisfaction values and N per session, and the earnings distributions.
- Whether the standard errors are robust to heteroskedasticity, and whether any outliers drive the mean difference.
