/**
 * Intake survey for "Claude Code for Academic Researchers".
 *
 * Builds the pre-course Google Form in the account of whoever runs it.
 * The form has four sections: (1) about you, (2) current AI use,
 * (3) tasks and agentic AI, (4) course goals.
 *
 * How to run:
 *   1. Go to https://script.google.com and click "New project".
 *   2. Delete the placeholder code, paste this whole file, and save.
 *   3. Select the function `buildIntakeSurvey` in the toolbar and click Run.
 *      Google will ask you to authorize access to Google Forms the first time.
 *   4. Open View > Logs (or the Execution log) to get the edit and share links.
 *
 * Running it again creates a second, separate form; it does not update the first.
 * The question list is mirrored in admin/intake_survey.md for review. If you
 * change one, change the other.
 */

const SURVEY_TITLE = 'Claude Code for Academic Researchers: Pre-Course Survey';

const SURVEY_DESCRIPTION =
  'This survey helps me understand who is taking the course, how you currently ' +
  'use AI, and what you want to get out of it, so I can pitch the sessions and ' +
  'examples at the right level. It takes about 10 minutes.\n\n' +
  'There are no right answers: "never" and "I don\'t know" are useful responses. ' +
  'Responses are seen only by the instructor and are used only to plan the course.';


// ---------------------------------------------------------------------------
// Helpers: one per Google Forms question type
// ---------------------------------------------------------------------------

/** Adds a single-answer multiple-choice question. */
function addSingleChoice(form, title, choices, options) {
  const settings = options || {};
  const item = form.addMultipleChoiceItem()
    .setTitle(title)
    .setChoiceValues(choices)
    .setRequired(settings.required !== false);
  if (settings.helpText) item.setHelpText(settings.helpText);
  if (settings.allowOther) item.showOtherOption(true);
  return item;
}

/** Adds a select-all-that-apply checkbox question. */
function addMultiChoice(form, title, choices, options) {
  const settings = options || {};
  const item = form.addCheckboxItem()
    .setTitle(title)
    .setChoiceValues(choices)
    .setRequired(settings.required !== false);
  if (settings.helpText) item.setHelpText(settings.helpText);
  if (settings.allowOther) item.showOtherOption(true);
  return item;
}

/** Adds a one-line text question. */
function addShortText(form, title, options) {
  const settings = options || {};
  const item = form.addTextItem()
    .setTitle(title)
    .setRequired(settings.required !== false);
  if (settings.helpText) item.setHelpText(settings.helpText);
  return item;
}

/** Adds a multi-line text question. */
function addLongText(form, title, options) {
  const settings = options || {};
  const item = form.addParagraphTextItem()
    .setTitle(title)
    .setRequired(settings.required !== false);
  if (settings.helpText) item.setHelpText(settings.helpText);
  return item;
}

/** Adds a grid question: one answer per row. */
function addGrid(form, title, rows, columns, options) {
  const settings = options || {};
  const item = form.addGridItem()
    .setTitle(title)
    .setRows(rows)
    .setColumns(columns)
    .setRequired(settings.required !== false);
  if (settings.helpText) item.setHelpText(settings.helpText);
  return item;
}

/** Starts a new page (section) of the form. */
function addSection(form, title, helpText) {
  const item = form.addPageBreakItem().setTitle(title);
  if (helpText) item.setHelpText(helpText);
  return item;
}


// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/** Section 1: who is taking the course. */
function addAboutYouSection(form) {
  form.addSectionHeaderItem().setTitle('About you');

  addShortText(form, 'Your name');

  addShortText(form, 'Institution and department',
    { helpText: 'e.g., IBEI; UPF, Department of Political and Social Sciences' });

  addSingleChoice(form, 'What is your current position?', [
    'Master\'s student',
    'PhD student, years 1-2',
    'PhD student, year 3 or later',
    'Postdoctoral researcher',
    'Assistant professor / lecturer',
    'Associate or full professor',
    'Research assistant or research staff',
    'Policy, NGO, or industry researcher',
  ], { allowOther: true });

  addMultiChoice(form, 'What is your field?', [
    'Political science',
    'International relations',
    'Economics',
    'Public policy',
    'Sociology',
    'Development studies',
    'History',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addLongText(form, 'In one or two sentences, what is your main research topic or current project?');

  addMultiChoice(form, 'Which kinds of methods do you use in your research?', [
    'Quantitative analysis of observational data (regression, panel data)',
    'Causal inference designs (DiD, IV, RD, synthetic control)',
    'Survey research or experiments',
    'Text-as-data / NLP',
    'Machine learning or other computational methods',
    'Spatial / GIS',
    'Formal theory / game theory',
    'Qualitative methods (interviews, case studies, process tracing)',
    'Archival or historical research',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addMultiChoice(form, 'Which software do you use for data analysis?', [
    'Stata',
    'R',
    'Python',
    'SPSS',
    'MATLAB',
    'Julia',
    'Excel / Google Sheets',
    'I don\'t currently do data analysis',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addSingleChoice(form, 'Which statement best describes your coding experience?', [
    'I don\'t write code',
    'I can run and lightly modify scripts that others wrote',
    'I write my own scripts for routine analyses',
    'I write long multi-step pipelines (cleaning, merging, estimation, output)',
    'I write reusable code: functions, packages, or tools other people use',
  ]);

  addGrid(form, 'How familiar are you with each of these tools?', [
    'The terminal / command line',
    'VS Code (or another code editor)',
    'git (version control)',
    'GitHub',
    'LaTeX (including Overleaf)',
    'Python virtual environments (venv, conda)',
  ], [
    'Never used',
    'Used a few times',
    'Use regularly',
  ]);
}

/** Section 2: how much and how they currently use AI. */
function addCurrentAiUseSection(form) {
  addSection(form, 'Your current AI use',
    'By "AI tools" I mean any generative AI: ChatGPT, Claude, Gemini, Copilot, ' +
    'Cursor, and so on. Answer about research and academic work, not personal use.');

  addSingleChoice(form, 'On how many days in a typical week do you use AI tools for research or academic work?', [
    'Never or almost never',
    'Less than one day a week',
    '1-2 days a week',
    '3-4 days a week',
    '5-7 days a week',
  ]);

  addSingleChoice(form, 'On a day when you do use AI for work, about how much time in total do you spend working with it?', [
    'Less than 15 minutes',
    '15-30 minutes',
    '30 minutes to 1 hour',
    '1-2 hours',
    '2-4 hours',
    'More than 4 hours',
    'Not applicable: I don\'t use AI for work',
  ], { helpText: 'Include time spent writing prompts, reading responses, and checking the output.' });

  addMultiChoice(form, 'Which AI tools have you used for work in the past three months?', [
    'ChatGPT',
    'Claude (web or desktop app)',
    'Gemini',
    'Microsoft Copilot',
    'GitHub Copilot',
    'Cursor',
    'Claude Code',
    'OpenAI Codex',
    'Gemini CLI',
    'Perplexity',
    'NotebookLM',
    'DeepSeek',
    'Elicit, Consensus, or another literature tool',
    'None',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addShortText(form, 'Which ONE AI tool do you use most?',
    { helpText: 'Write "none" if you don\'t use any.' });

  addMultiChoice(form, 'How do you usually interact with AI?', [
    'Chat in a web browser',
    'Desktop or mobile app',
    'Autocomplete suggestions while I type code (e.g., GitHub Copilot)',
    'A chat panel inside my code editor',
    'An agent that reads and edits files in my project folder (e.g., Claude Code, Cursor agent mode)',
    'Through the API from my own code',
    'Custom GPTs, Claude Projects, or Gems with saved instructions or files',
    'Voice',
    'I don\'t use AI',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addMultiChoice(form, 'Which AI plans do you currently have access to?', [
    'Free versions only',
    'An individual paid plan, about 20 EUR/USD a month (ChatGPT Plus, Claude Pro, Google AI Pro, Cursor Pro, etc.)',
    'A premium individual plan, about 100-200 EUR/USD a month (Claude Max, ChatGPT Pro, etc.)',
    'A team, education, or enterprise plan provided by my institution',
    'Pay-as-you-go API access (Anthropic, OpenAI, Google, etc.)',
    'Not sure',
  ], { allowOther: true, helpText: 'Select all that apply. Name the specific plan(s) under "Other" if you like.' });

  addMultiChoice(form, 'Who pays for your paid AI tools?', [
    'I pay myself',
    'My university or department',
    'A research grant',
    'My employer (outside a university)',
    'Not applicable: I only use free tools',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addSingleChoice(form, 'Do you currently have a Claude plan or API account that works with Claude Code (Claude Pro, Max, Team/Enterprise, or Anthropic API credits)?', [
    'Yes',
    'No, but I plan to get one before the course',
    'No, and I\'m not sure I can get one',
    'Not sure',
  ], { helpText: 'Claude Code requires one of these. This tells me whether access will be a problem for anyone.' });
}

/** Section 3: what they use AI for and their experience with agentic tools. */
function addTasksAndAgenticSection(form) {
  addSection(form, 'What you use AI for, and agentic AI',
    'By "agentic AI" I mean tools that take actions on your computer, such as reading ' +
    'and editing files in a project folder or running code, rather than only replying ' +
    'in a chat window. Examples: Claude Code, Cursor in agent mode, OpenAI Codex, Gemini CLI.');

  addMultiChoice(form, 'Which tasks do you currently use AI for?', [
    'Writing new code',
    'Debugging or explaining code',
    'Cleaning, reshaping, or merging data',
    'Translating code between languages (e.g., Stata to R or Python)',
    'Explaining statistical or econometric methods',
    'Getting feedback on a research design or identification strategy',
    'Finding literature',
    'Summarizing or explaining papers',
    'Brainstorming research ideas',
    'Drafting text (papers, proposals, abstracts)',
    'Editing, proofreading, or feedback on my writing',
    'Translating text between languages',
    'LaTeX formatting, tables, or figures',
    'Making slides',
    'Teaching (preparing materials, grading, feedback)',
    'Emails and administrative work',
    'I don\'t use AI for work',
  ], { allowOther: true, helpText: 'Select all that apply.' });

  addLongText(form, 'Describe the single most useful thing AI has done for your research so far.',
    { required: false });

  addLongText(form, 'Describe a time AI gave you something wrong or unhelpful for your research. How did you notice?',
    { required: false });

  addSingleChoice(form, 'Which statement best describes your experience with agentic AI tools?', [
    'I hadn\'t heard of them before this course',
    'I\'ve heard of them but never tried one',
    'I\'ve tried one once or twice',
    'I use one occasionally',
    'I use one regularly as part of my workflow',
  ]);

  addLongText(form, 'If you have used an agentic tool, which one, and what did you use it for?',
    { required: false });

  addMultiChoice(form, 'What concerns, if any, do you have about using AI in your research?', [
    'Errors or made-up results that I don\'t catch',
    'Not understanding what the code it wrote actually does',
    'Reproducibility',
    'Confidential or restricted-access data being sent to an AI provider',
    'Academic integrity, disclosure, or journal/university policies',
    'Losing my own skills',
    'Cost',
    'Environmental impact',
    'No particular concerns',
  ], { allowOther: true, helpText: 'Select all that apply.', required: false });

  addSingleChoice(form, 'Does your research use confidential or restricted-access data (e.g., data under a use agreement, IRB/ethics-protected data, administrative microdata)?', [
    'Yes',
    'No',
    'Not sure',
  ]);
}

/** Section 4: what they want from the course. */
function addCourseGoalsSection(form) {
  addSection(form, 'What you want from the course');

  addLongText(form, 'What do you want to get out of this course?');

  addLongText(form, 'Is there a specific task in your own research that you would like to be able to do with AI by the end of the course?',
    { helpText: 'Be as concrete as you can, e.g., "clean and merge the five survey waves for my second chapter."' });

  addMultiChoice(form, 'Which course topics are you most interested in?', [
    'How agentic AI differs from chatbots, and when to use which',
    'Managing long sessions and context',
    'Verifying and validating what the AI produces',
    'Building research pipelines (cleaning, merging, estimation, tables)',
    'git and version control',
    'Writing LaTeX in VS Code instead of Overleaf',
    'Collaborating on GitHub',
    'Building custom skills',
    'Connecting tools through MCP (e.g., Zotero for literature)',
    'Subagents (e.g., an AI referee or methodologist)',
    'Hooks and automation',
    'Using the Claude API from code',
  ], { helpText: 'Select up to five.' })
    .setValidation(FormApp.createCheckboxValidation()
      .requireSelectAtMost(5)
      .setHelpText('Please select at most five.')
      .build());

  addSingleChoice(form, 'For the capstone, which track are you leaning toward?', [
    'Guided replication of a provided paper',
    'Integrating Claude Code into one stage of my own project',
    'Undecided',
  ]);

  addSingleChoice(form, 'Have you completed the prework setup (Claude Code, Python, git, VS Code, LaTeX)?', [
    'Yes, everything is installed and working',
    'Partly: some things are installed or not working yet',
    'Not yet started',
  ]);

  addLongText(form, 'Anything else I should know (accessibility needs, scheduling constraints, questions)?',
    { required: false });
}


// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/** Creates the form and logs its edit and share links. */
function buildIntakeSurvey() {
  const form = FormApp.create(SURVEY_TITLE)
    .setDescription(SURVEY_DESCRIPTION)
    .setProgressBar(true)
    .setCollectEmail(false)
    .setAllowResponseEdits(true)
    .setConfirmationMessage('Thanks! See you in Session 1.');

  addAboutYouSection(form);
  addCurrentAiUseSection(form);
  addTasksAndAgenticSection(form);
  addCourseGoalsSection(form);

  // Newer Google Forms accounts create forms unpublished by default.
  // setPublished is only present where that feature exists.
  if (typeof form.setPublished === 'function') {
    form.setPublished(true);
  }

  Logger.log('Edit the form here:    ' + form.getEditUrl());
  Logger.log('Send students this:    ' + form.getPublishedUrl());
  // getItems() also returns section headers and page breaks; count only questions.
  const layoutTypes = [FormApp.ItemType.PAGE_BREAK, FormApp.ItemType.SECTION_HEADER];
  const questionCount = form.getItems()
    .filter(item => layoutTypes.indexOf(item.getType()) === -1)
    .length;
  Logger.log('Number of questions:   ' + questionCount);
}
