# AI-Assisted Development Best Practices Guide
**For Open Source Shell Script Projects on ASUS Merlin Routers**

*Based on successful TurboAsusSec development with Claude & Gemini*

---

## 🎯 Purpose

This guide helps developers leverage AI assistants (Claude, Gemini, ChatGPT, etc.) for shell script development, particularly for ASUS Merlin router projects. Whether starting a new project or continuing existing work, following these practices will maximize AI effectiveness and code quality.

---

## 📚 Table of Contents

1. [Quick Start Checklist](#quick-start-checklist)
2. [Project Context Template](#project-context-template)
3. [What AI Needs to Know](#what-ai-needs-to-know)
4. [Session Continuity Best Practices](#session-continuity-best-practices)
5. [Communication Patterns](#communication-patterns)
6. [Team Coordination](#team-coordination-multiple-ais)
7. [Common Pitfalls to Avoid](#common-pitfalls-to-avoid)
8. [Example: TurboAsusSec Case Study](#example-turboasussec-case-study)

---

## ✅ Quick Start Checklist

Before starting an AI-assisted development session:

### For New Projects
- [ ] Define project purpose (1-2 sentences)
- [ ] List target platform constraints (firmware, shell version, memory)
- [ ] Identify required dependencies and APIs
- [ ] Clarify what the project should NOT do
- [ ] Establish coding standards (POSIX shell, style guide)

### For Existing Projects
- [ ] Provide repository URL
- [ ] Share relevant conversation history (if continuing)
- [ ] Upload key script files
- [ ] Explain current issues/goals
- [ ] Note what's already working (don't break it!)

### For All Sessions
- [ ] Be clear about your role (architect, tester, developer)
- [ ] State your skill level honestly
- [ ] Define success criteria for the session
- [ ] Set expectations about testing/deployment

---

## 📋 Project Context Template

Copy this template and fill it out at the start of your first AI session:

```markdown
# Project Context for AI Assistant

## 1. Project Overview
**Project Name:** [Your project name]
**Purpose:** [What does it do in 1-2 sentences]
**Repository:** [GitHub URL if exists]
**Status:** [New / In Progress / Maintenance]

## 2. Platform & Constraints
**Target Platform:** ASUS Router with Merlin firmware [version]
**Shell Environment:** [POSIX sh / bash / ash]
**Memory Limit:** [e.g., 512MB RAM, 64MB JFFS]
**Required Firmware:** [Minimum version]
**Storage Location:** [e.g., /jffs/scripts/, /opt/]

## 3. Dependencies
**Required:**
- [e.g., Skynet firewall]
- [e.g., ipset command]

**Optional:**
- [e.g., sqlite3 for database queries]
- [e.g., Entware packages]

**Integration Points:**
- [e.g., Reads /tmp/skynet/skynet.log]
- [e.g., Writes to /jffs/addons/myproject/]

## 4. Technical Requirements
**Must Have:**
- POSIX shell compliance (no bashisms)
- Minimal resource usage
- No persistent background processes
- Graceful degradation if dependencies missing

**Should Have:**
- Smart caching for performance
- Clear error messages
- Logging for debugging

**Must NOT:**
- Use localStorage/sessionStorage (if web UI)
- Require root privileges beyond what Merlin provides
- Modify system files outside /jffs/
- Use non-standard commands without checking availability

## 5. Coding Standards
**Style:** [e.g., 4-space indent, no tabs]
**Naming:** [e.g., snake_case for functions, UPPER_CASE for globals]
**Comments:** [Required for all functions]
**Error Handling:** [Always use || and exit codes]

## 6. Project Structure
```
/jffs/addons/[project]/
├── scripts/
│   ├── main.sh
│   └── core.sh
├── logs/
└── config.txt
```

## 7. Known Issues
- [List any current bugs or limitations]
- [Note what you've tried that didn't work]

## 8. Current Goals
**This Session:**
- [Specific goal 1]
- [Specific goal 2]

**Next Milestone:**
- [What's the next major feature/release]

## 9. Your Role & Skill Level
**Your Role:** [Architect / Developer / Tester / All]
**Experience Level:** [Beginner / Intermediate / Advanced] in shell scripting
**AI's Role:** [Senior Developer / Code Reviewer / Debugger]

## 10. Testing Environment
**Router Model:** [e.g., RT-AX86U]
**Firmware Version:** [e.g., 388.8_2]
**Can You Test:** [Yes / No / Limited]
**Feedback Speed:** [Immediate / Within hours / Within days]
```

---

## 🧠 What AI Needs to Know

### Critical Information (Always Provide)

#### 1. **Platform Constraints**
```markdown
**Shell Limitations:**
- POSIX sh only (no bash arrays, no `[[`, no `local` in some versions)
- Limited commands (no `seq`, possibly no `column`)
- Must check command availability before use

**Example:**
```bash
# BAD - Bash specific
if [[ "$var" == "value" ]]; then

# GOOD - POSIX compliant
if [ "$var" = "value" ]; then
```

#### 2. **Resource Constraints**
```markdown
**Router has:**
- Limited RAM (256MB-1GB typical)
- Limited JFFS space (64-256MB)
- Flash storage with limited write cycles
- 4 cores typically

**Implications:**
- No heavy processing in loops
- Cache expensive operations
- Minimize disk writes
- Use /tmp for temporary data (RAM-based)
```

#### 3. **Integration Points**
Be explicit about what your script interacts with:
```markdown
**Reads from:**
- /tmp/skynet/skynet.log (Skynet logs)
- /opt/share/diversion/list/allowlist (Diversion whitelist)
- /jffs/.sys/AiProtectionMonitor/AiProtectionMonitor.db (AIProtection database)

**Writes to:**
- /jffs/addons/tcds/custom_whitelist.txt (User data)
- /tmp/tcds/*.cache (Temporary cache - cleared on reboot)

**Executes:**
- /jffs/scripts/firewall (Skynet commands)
- ipset (IPSet management)
- sqlite3 (Database queries - optional)
```

#### 4. **API & Command Documentation**
If integrating with existing tools, provide:
- Command syntax examples
- Expected output formats
- Error conditions
- Version differences

**Example:**
```markdown
**Skynet Whitelist API:**
```bash
# Add to whitelist
/jffs/scripts/firewall whitelist ip 192.168.1.100 comment "My device"

# List whitelist (note: doesn't have a direct command, must use ipset)
ipset list Skynet-Whitelist

# Output format:
# Name: Skynet-Whitelist
# Type: hash:net
# Members:
# 192.168.1.100
# 10.0.0.0/8
```
```

---

## 🔄 Session Continuity Best Practices

### Starting a New Session (Continuing Previous Work)

**Always provide:**

1. **Context Summary** (2-3 paragraphs)
```markdown
We're working on TurboAsusSec, a unified security management script for ASUS 
Merlin routers. It integrates Skynet (IP firewall), Diversion (DNS blocking), 
and AIProtection (threat detection) into a single CLI interface.

Previous sessions accomplished: [list key achievements]

Current status: [where you left off]

Today's goals: [what you want to work on]
```

2. **Relevant Conversation History**
   - Copy the last 2-3 exchanges from previous session
   - Or provide an executive summary
   - Include any key decisions made

3. **Current Code State**
   - Repository URL (AI can fetch latest)
   - Or upload the specific files you're working on
   - Note version numbers

4. **Open Issues**
   - What's not working
   - What feedback you received
   - What needs to be fixed

**Example Opening Message:**
```markdown
I'm continuing work on TurboAsusSec from our previous session. Here's where we are:

**What's Working:**
- v1.2.2 is deployed on GitHub
- Core functionality (menu, diagnostics, whitelist view) working
- Gemi fixed ipset detection bug

**Forum Feedback Received:**
- Users want "AIProtection" not "AIProtect" (consistency issue)
- tcds command doesn't work immediately after install - requires logout/login
- One user had symlink issue with tcds-core.sh path

**Today's Goals:**
1. Fix terminology consistency (AIProtection)
2. Improve installer post-install instructions
3. [anything else]

**Repository:** https://github.com/CutterSol/TurboAsusSec

Do you need me to upload any specific files, or can you fetch from the repo?
```

---

## 💬 Communication Patterns

### Effective Ways to Communicate with AI

#### 1. **Be Specific About Scope**
```markdown
❌ "Fix the script"
✅ "Fix the tcds-core.sh script - the ipset detection on line 294 is giving 
   false positives. Change from 'command -v ipset' to checking if 
   /usr/sbin/ipset is executable."
```

#### 2. **Provide Context for Decisions**
```markdown
❌ "Don't use bash arrays"
✅ "Don't use bash arrays - Merlin routers use POSIX sh by default, and bash 
   arrays will cause 'syntax error: unexpected "("' errors. Use space-separated 
   strings instead."
```

#### 3. **Show Examples of What Works**
```markdown
"Here's how Skynet handles similar functionality: [paste code example]
Can you follow this pattern for our whitelist function?"
```

#### 4. **Be Clear About Testing Limitations**
```markdown
"I can test this on my RT-AX86U with Merlin 388.8_2, but I won't have results 
until tomorrow evening. If there are multiple approaches, please recommend the 
safest one that's most likely to work."
```

#### 5. **Use Questions to Guide**
```markdown
Instead of: "The menu doesn't work right"

Try: "After the diagnostics run, the screen flashes and returns to the menu 
immediately. I think we need to add a pause. Should we:
A) Add a 'Press Enter to continue' prompt
B) Add a sleep timer
C) Something else?
What's the best practice for Merlin scripts?"
```

#### 6. **Request Specific Deliverables**
```markdown
"Please create:
1. Updated installer script with post-install message
2. Checklist of what changed for my testing
3. One-line command to test the fix

I'll upload to GitHub and test within 24 hours."
```

---

## 👥 Team Coordination (Multiple AIs)

If using multiple AI assistants (like TurboAsusSec with Claude + Gemini):

### 1. **Define Clear Roles**
```markdown
**Architect (You):** Overall vision, testing, final decisions
**Senior Developer (Claude):** Code review, documentation, architecture guidance
**Developer (Gemini):** Bug fixes, feature implementation, testing scripts
```

### 2. **Use Executive Summaries**
After each significant session, request an executive summary:
```markdown
"Please create an executive summary of this session including:
- What was accomplished
- What was approved/decided
- What needs to be done next
- Any blockers or concerns
I'll share this with [other AI] so we stay coordinated."
```

### 3. **Share Context Between AIs**
```markdown
"Here's the executive summary from my session with Gemini: [paste summary]
He fixed the ipset detection bug and added menu pause functionality.
Can you review his changes and let me know if they're production-ready?"
```

### 4. **Establish Boundaries**
```markdown
"Claude, you wrote the original core.sh file. Gemini should only modify it to 
fix bugs, not rewrite it. Please review his changes to ensure he followed this."
```

### 5. **Document Decisions**
Use your README or a DEVELOPMENT.md file to record:
- Architecture decisions
- Why certain approaches were chosen
- What was tried and didn't work
- Coding standards agreed upon

---

## ⚠️ Common Pitfalls to Avoid

### 1. **Insufficient Context**
```markdown
❌ "Make this work with Skynet"
✅ "Integrate with Skynet v7.5.1. Skynet stores logs at /tmp/mnt/[USB]/skynet/
   on USB installs or /tmp/skynet/ otherwise. We need to auto-detect the path.
   Here's Skynet's GitHub: [URL]"
```

### 2. **Assuming AI Knows Your Environment**
```markdown
❌ "The tcds command doesn't work"
✅ "After installation, 'tcds' gives '-sh: tcds: not found'. The symlink exists
   at /jffs/scripts/tcds and points to the right file. I checked $PATH and 
   /jffs/scripts is included. Here's the output: [paste]"
```

### 3. **Not Testing AI's Output**
```markdown
⚠️ ALWAYS test code before deploying!
- AI may not account for your specific environment
- Edge cases might not be covered
- POSIX compliance issues can be subtle
```

### 4. **Vague Problem Descriptions**
```markdown
❌ "It's broken"
✅ "Menu option 4 (View Skynet Logs) shows 'log file not found' even though
   the log exists at /tmp/mnt/MERLIN3/skynet/skynet.log. I think the path
   detection function isn't checking USB mounts correctly."
```

### 5. **Not Providing Examples**
```markdown
❌ "Add error handling"
✅ "Add error handling following this pattern from our diagnostics function:
   ```bash
   if [ ! -f "$AIPROTECT_DB" ]; then
       print_warning "AIProtect database not found"
       return 1
   fi
   ```"
```

### 6. **Changing Too Much at Once**
```markdown
❌ "Rewrite the entire script to be better"
✅ "Let's improve the whitelist function first. After we test that and it works,
   we'll move on to the blocklist function."
```

### 7. **Not Version Controlling**
```markdown
⚠️ ALWAYS use Git!
- Commit before asking AI to make changes
- Each AI session = one commit (or logical group)
- Tag releases (v1.2.0, v1.2.1, etc.)
- AI can help with commit messages
```

---

## 📊 Example: TurboAsusSec Case Study

### How We Successfully Used AI Assistance

#### Initial Session (Starting the Project)
**What Worked:**
1. ✅ Provided detailed platform constraints (POSIX sh, ASUS Merlin)
2. ✅ Shared examples of existing scripts (AIProtect analyzer)
3. ✅ Clearly defined integration points (Skynet, Diversion, AIProtection)
4. ✅ Established coding standards upfront (no bashisms)
5. ✅ Set realistic goals (start with diagnostics, not full management)

**Context Provided:**
```markdown
"We want to create a unified management script for ASUS Merlin routers that 
integrates Skynet (IP firewall), Diversion (DNS blocking), and AIProtection.

Target platform: POSIX sh on ASUS Merlin 384.15+
Resource constraints: ~1GB RAM, limited JFFS space
Must not: Use bash-specific features, run persistent daemons

Here's an existing AIProtect analyzer script: [uploaded file]
And Skynet's API: [shared GitHub link]

Our goal today: Create the core module and diagnostics system."
```

#### Continuation Sessions (Adding Features)
**What Worked:**
1. ✅ Shared conversation history or executive summaries
2. ✅ Noted what's working (don't break it)
3. ✅ Provided forum feedback from real users
4. ✅ Requested specific fixes with examples
5. ✅ Used multiple AIs with clear role definitions

**Example Message:**
```markdown
"Continuing TurboAsusSec development. Previous session with Gemini fixed the 
ipset detection bug. Here's his executive summary: [paste]

Forum feedback today:
- tcds command requires logout/login after install
- Terminology inconsistency: 'AIProtect' should be 'AIProtection'

Today's goals:
1. Review Gemini's fixes (are they production-ready?)
2. Fix installer to notify user about logout requirement
3. Update README terminology

Repository: https://github.com/CutterSol/TurboAsusSec
Can you fetch the latest code?"
```

#### Bug Fix Sessions (Real Issues)
**What Worked:**
1. ✅ Provided exact error messages
2. ✅ Showed environment details (paths, output)
3. ✅ Explained what was expected vs what happened
4. ✅ Asked for specific verification steps

**Example:**
```markdown
"User reported this error after installation:

# tcds
-sh: tcds: not found
# ls -al /jffs/scripts/tcds
lrwxrwxrwx 1 root root 33 Dec 6 08:51 /jffs/scripts/tcds -> /jffs/addons/tcds/scripts/tcds.sh

The symlink exists and points correctly. Another user said logging out/in fixed 
it - likely the alias in profile.add isn't sourced until new login.

Should we:
1. Add a message to installer: 'Please logout and login for tcds command to work'
2. Try to source profile.add during installation
3. Something else?

What's the Merlin convention for this?"
```

---

## 🛠️ Tools & Resources

### Helpful Links for AI-Assisted Development

**ASUS Merlin:**
- Firmware: https://www.asuswrt-merlin.net/
- Wiki: https://github.com/RMerl/asuswrt-merlin.ng/wiki
- Addons API: https://github.com/RMerl/asuswrt-merlin/wiki/Addons-API

**Common Integrations:**
- Skynet: https://github.com/Adamm00/IPSet_ASUS
- Diversion: https://diversion.ch/
- amtm: https://github.com/decoderman/amtm

**Shell Scripting:**
- POSIX Reference: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
- ShellCheck (linter): https://www.shellcheck.net/

**Git/GitHub:**
- GitHub CLI: https://cli.github.com/
- Git Basics: https://git-scm.com/book/en/v2

---

## 📝 Session Template

Copy this template for each AI session:

```markdown
# AI Development Session - [Date]

## Session Info
**Project:** [Name]
**Version:** [Current version]
**AI Assistant:** [Claude / Gemini / Other]
**Session Goal:** [What you want to accomplish]

## Current Status
[Brief summary of where the project is]

## Context Needed
[For new sessions: provide project context]
[For continuing: provide conversation history or executive summary]

## Today's Work
**Tasks:**
1. [Task 1]
2. [Task 2]

**Expected Deliverables:**
1. [File 1]
2. [File 2]

## Testing Plan
**How I'll Test:**
[Describe testing approach]

**When I'll Test:**
[Timeframe]

**Feedback Loop:**
[How quickly you'll report back]

## Questions for AI
1. [Question 1]
2. [Question 2]

## Post-Session
[ ] Code tested
[ ] Changes committed to Git
[ ] Executive summary requested
[ ] Shared with team (if applicable)
[ ] Updated README/documentation
```

---

## 🎯 Success Checklist

You're ready for productive AI-assisted development when:

- [ ] You have a clear, written project description
- [ ] Platform constraints are documented
- [ ] Integration points are identified
- [ ] You understand what the AI can/cannot test
- [ ] Coding standards are established
- [ ] You have examples of working code (if continuing project)
- [ ] You can test AI's output (or have a tester)
- [ ] You're using version control (Git)
- [ ] You communicate specific, actionable requests
- [ ] You provide feedback on AI's output

---

## 💡 Pro Tips

### 1. **Start Small**
Don't ask AI to build your entire project in one session. Start with:
- Core utility functions
- Basic menu system
- Simple integration (one tool at a time)
- Add features incrementally

### 2. **Iterate Based on Real Feedback**
```markdown
Theory → Implementation → Testing → User Feedback → Refinement
```

### 3. **Document as You Go**
Ask AI to:
- Add inline comments explaining complex logic
- Update README with new features
- Create troubleshooting sections
- Generate usage examples

### 4. **Use AI for Code Review**
```markdown
"Here's the code Gemini wrote to fix [issue]. Can you review it for:
- POSIX compliance
- Potential bugs
- Performance issues
- Better approaches
Would you approve this for production?"
```

### 5. **Leverage AI's Strengths**
AI is excellent at:
- Converting between coding styles (bash → POSIX)
- Writing boilerplate code
- Creating documentation
- Explaining complex code
- Suggesting error handling
- Finding POSIX alternatives to bash features

AI needs help with:
- Understanding your specific environment
- Testing on actual hardware
- Knowing community preferences/conventions
- Making architecture decisions
- Prioritizing features

---

## 🎓 Learning Opportunity

**For Beginners:**
Use AI to learn while building:
```markdown
"Can you explain why this approach is better than [alternative]?"
"What does this shell syntax mean: ${var:-default}?"
"Why must we check for command availability first?"
```

**For Experienced Developers:**
Use AI to:
- Speed up boilerplate code
- Explore alternative approaches
- Catch edge cases you might miss
- Generate comprehensive test cases
- Create documentation faster

---

## 📢 Community Contribution

### Sharing Your AI-Assisted Project

When posting to forums (like SNBForums):

**Be Transparent:**
```markdown
"This project was developed with AI assistance (Claude/Gemini). 
All code has been tested on [router model] with [firmware version]."
```

**Provide Quality Documentation:**
- Installation instructions
- Troubleshooting section
- Known limitations
- How to contribute

**Accept Feedback Gracefully:**
- Users will find bugs
- Community might have better approaches
- Terminology might need correction (like AIProtection vs AIProtect)

**Iterate Based on Real Use:**
- Real users find edge cases AI can't predict
- Community testing is invaluable
- Fix issues as they're reported

---

## 🚀 Example First Message to AI

Here's a complete example of starting a new project:

```markdown
Hi! I want to create a network monitoring script for ASUS routers running 
Merlin firmware. Here's the context:

**Project Overview:**
- Name: NetMonitor
- Purpose: Track and visualize bandwidth usage per device
- Status: New project

**Platform:**
- ASUS RT-AX86U (and similar models)
- Merlin firmware 388.x
- POSIX sh (no bash features)
- 512MB RAM, 64MB JFFS space

**Dependencies:**
- Requires: iptables (built-in)
- Optional: sqlite3 (via Entware for historical data)

**Integration Points:**
- Read from: /proc/net/ip_conntrack (connection tracking)
- Write to: /jffs/addons/netmonitor/data.db (if sqlite3 available)
- Store in: /tmp/netmonitor/ (temporary processing)

**Must Have:**
- POSIX shell compliance
- Works without Entware (degraded mode ok)
- CLI interface (menu-driven)
- < 10MB memory usage

**Must NOT:**
- Require bash
- Run persistent daemon
- Modify system iptables rules (read-only)

**Coding Standards:**
- Functions: lowercase_with_underscores
- Global vars: UPPERCASE_WITH_UNDERSCORES
- Indent: 4 spaces
- Always check command availability before use

**My Role:** Architect & Tester
**My Skill Level:** Intermediate shell scripting
**Your Role:** Senior Developer
**I Can Test:** Yes, on RT-AX86U within 24 hours

**Today's Goal:**
Create a basic framework with:
1. Core utility functions (logging, color output, error handling)
2. Device detection function (list connected devices)
3. Simple CLI menu

Can you help me start with the core module? I'd like to follow patterns 
similar to how Skynet is structured.
```

---

## 📚 Conclusion

AI-assisted development is powerful when you:
1. **Provide clear context** about your platform and goals
2. **Communicate specifically** about what you need
3. **Test everything** before deploying
4. **Iterate based on real feedback**
5. **Document as you go**

This guide should help developers in the ASUS Merlin community (and beyond) 
leverage AI to create better tools faster, while maintaining quality and 
following best practices.

---

**Questions?**
Open an issue on GitHub or post in SNBForums. The community is here to help!

---

*This guide was created through AI-assisted development of TurboAsusSec*  
*Last Updated: December 2025*  
*License: GPL-3.0*
