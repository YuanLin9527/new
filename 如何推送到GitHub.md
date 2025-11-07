# 如何推送到GitHub

## 📝 当前状态

✅ 本地Git仓库已初始化  
✅ 代码已提交到本地仓库（17个文件，3115行代码）  
✅ GitHub Actions自动编译配置已添加  

---

## 🚀 推送步骤

### 步骤1：在GitHub上创建仓库

1. 打开浏览器，访问：https://github.com/new

2. 填写仓库信息：
   - **Repository name**: `iOS-NetworkDiagnosisSDK` (或你喜欢的名字)
   - **Description**: `iOS网络诊断SDK - 游戏内悬浮窗、Ping、Traceroute、Telnet`
   - **Public / Private**: 选择 Public（公开）或 Private（私有）
   - ⚠️ **不要勾选** "Add a README file"（我们已经有了）
   - ⚠️ **不要勾选** "Add .gitignore"（我们已经有了）

3. 点击 **"Create repository"** 按钮

---

### 步骤2：复制仓库URL

创建完成后，GitHub会显示快速设置页面，复制仓库URL：

```
https://github.com/你的用户名/iOS-NetworkDiagnosisSDK.git
```

或者（如果使用SSH）：

```
git@github.com:你的用户名/iOS-NetworkDiagnosisSDK.git
```

---

### 步骤3：在本地添加远程仓库并推送

打开 **PowerShell** 或 **Git Bash**，执行以下命令：

```powershell
# 进入SDK目录
cd E:\youxisdkxuanfuchuang\MyApplication\iOS_NetworkDiagnosisSDK

# 添加远程仓库（替换成你的仓库URL）
git remote add origin https://github.com/你的用户名/iOS-NetworkDiagnosisSDK.git

# 推送到GitHub
git push -u origin master
```

如果使用SSH（需要先配置SSH密钥）：

```bash
git remote add origin git@github.com:你的用户名/iOS-NetworkDiagnosisSDK.git
git push -u origin master
```

---

## 🔐 如果需要登录

第一次推送时，Git可能会要求你登录：

### 方式1：使用Personal Access Token（推荐）

1. 访问：https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 生成Token并复制
5. 推送时使用Token作为密码

### 方式2：使用GitHub Desktop

1. 下载安装 GitHub Desktop：https://desktop.github.com/
2. 登录你的GitHub账号
3. File → Add Local Repository → 选择 `iOS_NetworkDiagnosisSDK` 文件夹
4. 点击 "Publish repository" 按钮

---

## ✅ 推送成功后

### 1. 查看仓库

访问：`https://github.com/你的用户名/iOS-NetworkDiagnosisSDK`

你应该能看到所有文件：
- ✅ README.md 显示为仓库首页
- ✅ 集成说明.md
- ✅ 所有源代码文件
- ✅ .github/workflows/build.yml

### 2. 自动编译（GitHub Actions）

推送后，GitHub会自动开始编译：

1. 访问：`https://github.com/你的用户名/iOS-NetworkDiagnosisSDK/actions`
2. 点击最新的工作流运行
3. 等待编译完成（约3-5分钟）
4. 编译成功后，点击 "Artifacts" 下载编译好的 `.a` 文件

**这样你就不需要Mac也能获得编译后的SDK了！** 🎉

### 3. 下载编译产物

编译成功后：
- 点击 Actions → 最新的运行记录
- 在页面底部找到 "Artifacts"
- 下载 `iOS-NetworkDiagnosisSDK.zip`
- 解压后就能得到：
  - `NetworkDiagnosisSDK.xcframework`
  - `libNetworkDiagnosisSDK.a`
  - 所有 `.h` 头文件

---

## 🎯 快速命令（复制粘贴）

```powershell
# 进入目录
cd E:\youxisdkxuanfuchuang\MyApplication\iOS_NetworkDiagnosisSDK

# 添加远程仓库（⚠️ 替换成你的URL）
git remote add origin https://github.com/你的用户名/iOS-NetworkDiagnosisSDK.git

# 检查远程仓库
git remote -v

# 推送代码
git push -u origin master
```

---

## 🔧 常见问题

### 问题1：推送失败，提示 "remote origin already exists"

**解决方法：**
```powershell
git remote remove origin
git remote add origin https://github.com/你的用户名/iOS-NetworkDiagnosisSDK.git
git push -u origin master
```

### 问题2：推送失败，提示 "Authentication failed"

**解决方法：**
- 使用Personal Access Token代替密码
- 或使用GitHub Desktop

### 问题3：想改为SSH方式

**解决方法：**
```powershell
git remote set-url origin git@github.com:你的用户名/iOS-NetworkDiagnosisSDK.git
```

---

## 📦 后续更新代码

如果修改了代码，推送更新：

```powershell
cd E:\youxisdkxuanfuchuang\MyApplication\iOS_NetworkDiagnosisSDK

# 查看修改
git status

# 添加修改的文件
git add .

# 提交
git commit -m "更新说明"

# 推送
git push
```

GitHub Actions会自动重新编译！

---

## 🎉 完成

推送成功后，你就可以：
- ✅ 分享GitHub链接给客户
- ✅ 通过GitHub Actions自动编译（不需要Mac）
- ✅ 版本管理和协作开发
- ✅ 客户可以直接clone仓库自己编译

**GitHub地址格式：**
```
https://github.com/你的用户名/iOS-NetworkDiagnosisSDK
```

