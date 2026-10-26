# Pre-Course Survey: Question List

Readable copy of the questions built by [intake_survey_form.gs](intake_survey_form.gs). If you change one, change the other.

To create the form: open https://script.google.com, start a new project, paste the `.gs` file, run `buildIntakeSurvey`, and copy the links from the execution log.

Notation: **(one)** = choose one; **(all)** = select all that apply; **(text)** = short answer; **(para)** = paragraph; **[+Other]** = includes a free-text "Other" option; *optional* = not required. Everything else is required.

---

## Intro text

> This survey helps me understand who is taking the course, how you currently use AI, and what you want to get out of it, so I can pitch the sessions and examples at the right level. It takes about 10 minutes.
>
> There are no right answers: "never" and "I don't know" are useful responses. Responses are seen only by the instructor and are used only to plan the course.

---

## Section 1. About you

1. **Your name (optional)** (text, *optional*)
2. **Institution and department** (text)
3. **What is your current position?** (one) [+Other]
   Master's student · PhD student, years 1-2 · PhD student, year 3 or later · Postdoctoral researcher · Assistant professor / lecturer · Associate or full professor · Research assistant or research staff · Policy, NGO, or industry researcher
4. **What is your field?** (all) [+Other]
   Political science · International relations · Economics · Public policy · Sociology · Development studies · History
5. **In one or two sentences, what is your main research topic or current project?** (para)
6. **Which kinds of methods do you use in your research?** (all) [+Other]
   Quantitative analysis of observational data · Causal inference designs (DiD, IV, RD, synthetic control) · Survey research or experiments · Text-as-data / NLP · Machine learning or other computational methods · Spatial / GIS · Formal theory / game theory · Qualitative methods · Archival or historical research
7. **Which software do you use for data analysis?** (all) [+Other]
   Stata · R · Python · SPSS · MATLAB · Julia · Excel / Google Sheets · I don't currently do data analysis
8. **Which statement best describes your coding experience?** (one)
   I don't write code · I can run and lightly modify scripts that others wrote · I write my own scripts for routine analyses · I write long multi-step pipelines · I write reusable code: functions, packages, or tools other people use
9. **How familiar are you with each of these tools?** (grid: Never used / Used a few times / Use regularly)
   Terminal / command line · VS Code (or another editor) · git · GitHub · LaTeX (including Overleaf) · Python virtual environments

## Section 2. Your current AI use

*Section note: "AI tools" means any generative AI. Answer about research and academic work, not personal use.*

10. **On how many days in a typical week do you use AI tools for research or academic work?** (one)
    Never or almost never · Less than one day a week · 1-2 days · 3-4 days · 5-7 days
11. **On a day when you do use AI for work, about how much time in total do you spend working with it?** (one)
    <15 min · 15-30 min · 30 min-1 h · 1-2 h · 2-4 h · >4 h · Not applicable
12. **Which AI tools have you used for work in the past three months?** (all) [+Other]
    ChatGPT · Claude (web/desktop) · Gemini · Microsoft Copilot · GitHub Copilot · Cursor · Claude Code · OpenAI Codex · Gemini CLI · Perplexity · NotebookLM · DeepSeek · Elicit/Consensus/other literature tool · None
13. **Which ONE AI tool do you use most?** (text)
14. **How do you usually interact with AI?** (all) [+Other]
    Browser chat · Desktop or mobile app · Autocomplete while typing code · Chat panel inside code editor · Agent that reads and edits files in my project folder · API from my own code · Custom GPTs / Claude Projects / Gems · Voice · I don't use AI
15. **Which AI plans do you currently have access to?** (all) [+Other]
    Free only · Individual paid ~20/month · Premium individual ~100-200/month · Team/education/enterprise via institution · Pay-as-you-go API · Not sure
16. **Who pays for your paid AI tools?** (all) [+Other]
    I pay myself · University or department · Research grant · Employer outside a university · Not applicable: free tools only

## Section 3. What you use AI for, and agentic AI

*Section note defines agentic AI: tools that take actions on your computer (reading/editing files, running code) rather than only replying in chat. Examples: Claude Code, Cursor agent mode, OpenAI Codex, Gemini CLI.*

17. **Which tasks do you currently use AI for?** (all) [+Other]
    Writing new code · Debugging or explaining code · Cleaning/reshaping/merging data · Translating code between languages · Explaining statistical methods · Feedback on research design · Finding literature · Summarizing papers · Brainstorming research ideas · Drafting text · Editing/proofreading · Translating text · LaTeX/tables/figures · Slides · Teaching · Emails and admin · I don't use AI for work
18. **Describe the single most useful thing AI has done for your research so far.** (para, *optional*)
19. **Describe a time AI gave you something wrong or unhelpful for your research. How did you notice?** (para, *optional*)
20. **Which statement best describes your experience with agentic AI tools?** (one)
    Hadn't heard of them · Heard of them, never tried · Tried once or twice · Use occasionally · Use regularly as part of my workflow
21. **If you have used an agentic tool, which one, and what did you use it for?** (para, *optional*)
22. **What concerns, if any, do you have about using AI in your research?** (all, *optional*) [+Other]
    Errors I don't catch · Not understanding the code it wrote · Reproducibility · Confidential data sent to a provider · Academic integrity / disclosure / policies · Losing my own skills · Cost · Environmental impact · No particular concerns
23. **Does your research use confidential or restricted-access data?** (one)
    Yes · No · Not sure

## Section 4. What you want from the course

24. **What do you want to get out of this course?** (para)
25. **Is there a specific task in your own research that you would like to be able to do with AI by the end of the course?** (para)
26. **Which course topics are you most interested in?** (all, max 5)
    Agentic AI vs. chatbots · Managing long sessions and context · Verifying AI output · Research pipelines · git · LaTeX in VS Code · GitHub collaboration · Custom skills · MCP (e.g., Zotero) · Subagents · Hooks and automation · Claude API
27. **Anything else I should know?** (para, *optional*)
