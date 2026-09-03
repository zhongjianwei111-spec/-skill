# Agent Skills Portable Pack 使用说明

这个目录用于统一管理、安装、检查、更新和扩展常用 Agent Skills。

适用场景：

- 新电脑快速恢复开发 Skill
- Codex / Claude Code / Cursor / Gemini CLI 等 Agent 共用一套 Skill
- 后续新增 Skill 时不再修改大量脚本
- 区分核心 Skill 和按需 Skill
- 定期检查和更新 Skill

---

## 目录结构

推荐目录：

```text
my-agent-skills-pack/
│
├─ skills.json          # Skill 清单，唯一配置来源
├─ install.ps1          # 安装 Skill
├─ check.ps1            # 检查环境和 Skill
├─ update.ps1           # 更新 Skill
├─ add-skill.ps1        # 新增 Skill 到 skills.json
├─ audit.ps1            # 可选：安全审计
├─ README.md            # 本说明文件
└─ sources.txt          # 可选：记录 Skill 来源
```

---

# 一、第一次使用

进入目录：

```powershell
cd D:\my-agent-skills-pack
```

如果 Windows 不允许执行 PowerShell 脚本，可仅对当前终端临时放开：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

这个设置只影响当前 PowerShell 窗口，关闭后失效。

---

# 二、最常用命令

## 1. 安装核心 Skill

```powershell
.\install.ps1
```

等价于：

```powershell
.\install.ps1 -Profile core
```

作用：

安装所有 `tier = core` 的 Skill。

当前核心 Skill：

```text
create-plan
grill-me
diagnosing-bugs
tdd
playwright
```

适合：

- 新电脑第一次初始化
- 新装 Codex / Claude Code / Cursor 后恢复基础能力
- 日常开发环境快速初始化

---

## 2. 检查环境

```powershell
.\check.ps1
```

作用：

检查：

```text
Node
npm
npx
核心 Skill 是否完整
已安装 Agent 是否可以使用核心 Skill
```

结果通常分为：

```text
PASS  = Agent 已安装，并且 Skill 齐全
SKIP  = Agent 本身没有安装，不算错误
FAIL  = Agent 已安装，但核心 Skill 不完整
```

理想结果：

```text
Codex           PASS
Claude Code     PASS
Cursor          PASS
Gemini CLI      SKIP

Core skills: 5/5

ENVIRONMENT READY
```

---

## 3. 更新所有已安装 Skill

```powershell
.\update.ps1
```

作用：

检查 Skill 上游仓库并更新到最新版本。

正常输出类似：

```text
Checking skills from source: mattpocock/skills
Checking skills from source: composio-community/awesome-codex-skills
Checking skills from source: openai/skills

All global skills are up to date
```

建议：

```text
不要设置无人值守自动更新。
更新完成后最好再执行 audit.ps1 和 check.ps1。
```

推荐流程：

```powershell
.\update.ps1
.\audit.ps1
.\check.ps1
```

如果没有 `audit.ps1`，至少：

```powershell
.\update.ps1
.\check.ps1
```

---

# 三、安装按需 Skill

## 1. 安装全部按需 Skill

```powershell
.\install.ps1 -Profile optional
```

作用：

安装 `skills.json` 中：

```json
"tier": "optional"
```

的所有 Skill。

适合：

想一次性补齐所有扩展 Skill。

---

## 2. 安装全部 Skill

```powershell
.\install.ps1 -Profile all
```

作用：

安装：

```text
core
+
optional
```

全部 Skill。

适合：

新电脑完整恢复所有 Skill。

不建议每台机器都默认用这个命令，因为有些 Skill 依赖额外工具或权限。

---

# 四、按分类安装 Skill

## GitHub 类

```powershell
.\install.ps1 -Category github
```

通常包括：

```text
gh-fix-ci
gh-address-comments
```

用途：

```text
GitHub Actions CI 排错
PR Review 评论处理
```

注意：

通常需要安装 GitHub CLI：

```powershell
gh --version
```

并登录：

```powershell
gh auth login
```

---

## Writing 类

```powershell
.\install.ps1 -Category writing
```

通常包括：

```text
stop-slop
```

用途：

```text
README
PR 描述
技术文档
文章
```

用于减少明显 AI 腔和机械表达。

---

## Research 类

```powershell
.\install.ps1 -Category research
```

通常包括：

```text
last30days
```

用途：

调查最近 30 天：

```text
X
Reddit
YouTube
Hacker News
GitHub
Web
```

适合：

```text
AI 工具趋势
框架趋势
社区评价
最近版本变化
```

---

## Knowledge 类

```powershell
.\install.ps1 -Category knowledge
```

通常包括：

```text
book-to-skill
cangjie-skill
```

用途：

将：

```text
PDF
书籍
长文
课程
视频
播客
```

整理为可复用 Skill 或方法论。

---

# 五、只安装指定 Skill

## 安装一个 Skill

例如：

```powershell
.\install.ps1 -Skill last30days
```

只安装：

```text
last30days
```

---

## 一次安装多个 Skill

```powershell
.\install.ps1 -Skill stop-slop,last30days
```

或者：

```powershell
.\install.ps1 -Skill gh-fix-ci,gh-address-comments
```

作用：

只安装指定 Skill，不影响其他 Skill。

---

# 六、新增 Skill

以后看到新的好用 Skill，不要手动往 `install.ps1` 里复制命令。

统一使用：

```powershell
.\add-skill.ps1
```

---

## 示例：新增一个普通按需 Skill

```powershell
.\add-skill.ps1 `
  -Name vue3-review `
  -Source xxx/vue-agent-skills `
  -Selector vue3-review `
  -Category development `
  -Tier optional
```

含义：

```text
Name
Skill 名称

Source
Skill 所在 GitHub 仓库或地址

Selector
仓库中真正的 Skill 名称

Category
Skill 分类

Tier
core 或 optional
```

新增后安装：

```powershell
.\install.ps1 -Skill vue3-review
```

再检查：

```powershell
.\check.ps1
```

---

# 七、Skill 分类说明

当前建议使用这些分类：

```text
development
browser
github
writing
research
knowledge
other
```

示例：

```text
create-plan          development
grill-me             development
diagnosing-bugs      development
tdd                   development

playwright            browser

gh-fix-ci             github
gh-address-comments   github

stop-slop             writing

last30days            research

book-to-skill         knowledge
cangjie-skill         knowledge
```

---

# 八、Core 和 Optional 的区别

## core

核心 Skill。

特点：

```text
每台开发机器都建议安装
check.ps1 会把它们作为必须项检查
缺失会导致 FAIL
```

当前：

```text
create-plan
grill-me
diagnosing-bugs
tdd
playwright
```

---

## optional

按需 Skill。

特点：

```text
不是每台电脑都必须安装
没有安装不会导致核心检查失败
根据项目或工作内容选择安装
```

例如：

```text
stop-slop
gh-fix-ci
gh-address-comments
last30days
book-to-skill
cangjie-skill
```

---

# 九、禁用 Skill

如果某个 Skill 暂时不想维护，不需要删除配置。

打开：

```text
skills.json
```

把：

```json
"enabled": true
```

改成：

```json
"enabled": false
```

这样它将不参与正常安装和检查流程。

以后需要时改回：

```json
"enabled": true
```

即可。

---

# 十、skills.json 是核心配置

以后尽量遵守：

```text
Skill 信息只维护在 skills.json
```

不要同时在：

```text
install.ps1
check.ps1
README.md
```

手动维护同一份 Skill 清单。

脚本应该从：

```text
skills.json
```

自动读取。

这样以后新增第 6、10、20 个 Skill 时，不需要反复修改脚本。

---

# 十一、查看已安装 Skill

查看全部全局 Skill：

```powershell
npx.cmd --yes --package=skills@latest skills list -g
```

查看 Codex：

```powershell
npx.cmd --yes --package=skills@latest skills list -g -a codex
```

查看 Claude Code：

```powershell
npx.cmd --yes --package=skills@latest skills list -g -a claude-code
```

查看 Cursor：

```powershell
npx.cmd --yes --package=skills@latest skills list -g -a cursor
```

查看 Gemini CLI：

```powershell
npx.cmd --yes --package=skills@latest skills list -g -a gemini-cli
```

---

# 十二、查看公共 Skill 目录

当前公共 Skill 通常位于：

```powershell
Get-ChildItem "$HOME\.agents\skills"
```

例如：

```text
C:\Users\<用户名>\.agents\skills
```

应该能看到：

```text
create-plan
diagnosing-bugs
grill-me
playwright
tdd
```

---

# 十三、查看 Codex Skill 目录

```powershell
Get-ChildItem "$HOME\.codex\skills"
```

注意：

部分 Skill 可能通过：

```text
~\.agents\skills
```

被兼容 Agent 共用，不一定全部复制到：

```text
~\.codex\skills
```

---

# 十四、安全检查

如果目录里有：

```text
audit.ps1
```

执行：

```powershell
.\audit.ps1
```

用途：

检查 Skill 中：

```text
脚本文件
网络请求
删除命令
shell 调用
Token/API Key 关键词
敏感目录访问
```

注意：

```text
被 audit.ps1 标黄 ≠ 恶意
```

例如 Playwright 因为需要：

```text
浏览器控制
CLI
网页访问
截图
表单填写
```

权限天然比纯 Prompt Skill 高。

---

# 十五、推荐安全更新流程

不要只执行：

```powershell
.\update.ps1
```

更推荐：

```powershell
.\update.ps1
.\audit.ps1
.\check.ps1
```

含义：

```text
更新
 ↓
检查新版本有没有高风险变化
 ↓
确认核心 Skill 仍然完整
```

---

# 十六、新电脑完整恢复流程

假设已经把本项目上传到 Git。

第一步：

```powershell
git clone <你的仓库地址>
```

第二步：

```powershell
cd my-agent-skills-pack
```

第三步：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

仅在系统禁止执行脚本时需要。

第四步：

```powershell
.\install.ps1
```

第五步：

```powershell
.\check.ps1
```

如果还要所有扩展：

```powershell
.\install.ps1 -Profile optional
```

或者一次装全部：

```powershell
.\install.ps1 -Profile all
```

---

# 十七、推荐日常使用流程

## 平时不用动

Skill 安装完成以后，正常开发即可。

---

## 想更新 Skill

```powershell
.\update.ps1
.\check.ps1
```

---

## 发现新 Skill

```powershell
.\add-skill.ps1 ...
```

然后：

```powershell
.\install.ps1 -Skill Skill名称
```

---

## 换电脑

```powershell
git clone <仓库>
cd my-agent-skills-pack
.\install.ps1
.\check.ps1
```

---

# 十八、核心 Skill 的使用场景

## grill-me

需求不清楚时：

```text
使用 grill-me。
先把这个需求中所有未确认的问题问清楚，不要立即编码。
```

作用：

```text
需求澄清
边界确认
避免 AI 自己猜需求
```

---

## create-plan

准备开发前：

```text
使用 create-plan。
分析当前项目，给出完整实施计划，暂时不要修改代码。
```

作用：

```text
扫描项目
制定步骤
明确修改范围
评估风险
```

---

## tdd

核心逻辑开发：

```text
使用 tdd。
先写失败测试，再实现功能。
```

作用：

```text
测试驱动开发
降低回归风险
```

---

## diagnosing-bugs

出现 Bug：

```text
使用 diagnosing-bugs。
先定位根因，不要直接猜测和修改。
```

作用：

```text
复现
缩小范围
验证假设
找到根因
修复
回归
```

---

## playwright

页面开发完成：

```text
使用 playwright。

打开当前前端项目并验证：
1. 页面打开
2. 表单输入
3. 搜索
4. 新增
5. 编辑
6. 删除
7. 分页
8. Console
9. Network
10. 页面 UI
```

作用：

```text
真实浏览器自动化
前端页面验收
UI 流程测试
```

---

# 十九、推荐开发工作流

```text
需求
 ↓
grill-me
 ↓
需求确认
 ↓
create-plan
 ↓
开发方案
 ↓
tdd
 ↓
实现
 ↓
出现问题
 ↓
diagnosing-bugs
 ↓
修复
 ↓
playwright
 ↓
浏览器验收
 ↓
完成
```

---

# 二十、常见问题

## 1. npx 报 could not determine executable to run

使用：

```powershell
npx.cmd --yes --package=skills@latest skills --version
```

不要使用旧写法：

```powershell
npx skills@latest ...
```

---

## 2. Node 版本不满足要求

检查：

```powershell
node -v
```

如果使用 nvm：

```powershell
nvm list
```

安装：

```powershell
nvm install 22.20.0
```

切换：

```powershell
nvm use 22.20.0
```

---

## 3. GitHub 克隆失败

测试：

```powershell
Test-NetConnection github.com -Port 443
```

再测试 Git：

```powershell
git ls-remote https://github.com/openai/skills.git
```

检查 Git 代理：

```powershell
git config --global --get-regexp "http.*proxy"
```

---

## 4. PowerShell 不允许运行脚本

执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

然后重新：

```powershell
.\install.ps1
```

---

## 5. Gemini CLI 显示 SKIP

如果本机没有安装 Gemini CLI：

```text
SKIP 是正常状态
```

不需要为了通过检查专门创建：

```text
~\.gemini
```

---

## 6. Optional Skill 没安装

正常。

只有：

```text
core
```

Skill 缺失才应该影响环境状态。

---

# 二十一、常用命令速查

```powershell
# 进入目录
cd D:\my-agent-skills-pack

# 安装核心 Skill
.\install.ps1

# 检查
.\check.ps1

# 更新
.\update.ps1

# 安全检查
.\audit.ps1

# 安装全部 optional
.\install.ps1 -Profile optional

# 安装全部
.\install.ps1 -Profile all

# 安装 GitHub 类
.\install.ps1 -Category github

# 安装写作类
.\install.ps1 -Category writing

# 安装调研类
.\install.ps1 -Category research

# 安装知识类
.\install.ps1 -Category knowledge

# 安装单个 Skill
.\install.ps1 -Skill last30days

# 安装多个 Skill
.\install.ps1 -Skill stop-slop,last30days

# 查看全局 Skill
npx.cmd --yes --package=skills@latest skills list -g

# 查看 Codex Skill
npx.cmd --yes --package=skills@latest skills list -g -a codex

# 查看公共 Skill 文件夹
Get-ChildItem "$HOME\.agents\skills"

# 更新后推荐检查
.\update.ps1
.\audit.ps1
.\check.ps1
```

---

# 二十二、最少需要记住的 6 条命令

如果其他都忘了，只记住：

```powershell
# 安装核心
.\install.ps1

# 检查
.\check.ps1

# 更新
.\update.ps1

# 安全检查
.\audit.ps1

# 安装指定 Skill
.\install.ps1 -Skill Skill名称

# 安装所有 Skill
.\install.ps1 -Profile all
```

---

# 二十三、当前核心 Skill

```text
create-plan
grill-me
diagnosing-bugs
tdd
playwright
```

---

# 二十四、当前推荐按需 Skill

```text
stop-slop
gh-fix-ci
gh-address-comments
last30days
book-to-skill
cangjie-skill
```

后续新增 Skill 时：

```text
不要修改大量脚本
优先修改 skills.json
或者使用 add-skill.ps1
```

