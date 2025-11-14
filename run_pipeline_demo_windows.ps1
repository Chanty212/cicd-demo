# ============================================
# Windows PowerShell Script: run_pipeline_demo_windows.ps1
# Purpose: Launch Jenkins, expose via ngrok, and perform demo Git commit
# ============================================

# --- User Configuration ---
$JenkinsContainerName = "jenkins"
$JenkinsPort = 8080
$JenkinsVolume = "$env:USERPROFILE\jenkins_home"
$NgrokPath = "C:\Users\Veteran\AppData\Local\Microsoft\WindowsApps\ngrok.exe
$GitRepoPath = "C:\Users\Veteran\OneDrive\Desktop\ci-cd-demo"  # LOCAL folder of your repo
$TestCommitMessage = "Demo: automated pipeline test"

# --- 1. Start Jenkins Docker Container ---
Write-Host "`n=== Checking Jenkins container ==="
$container = docker ps -a --filter "name=$JenkinsContainerName" --format "{{.Names}}"
if ($container -eq $JenkinsContainerName) {
    Write-Host "Jenkins container exists. Starting..."
    docker start $JenkinsContainerName
} else {
    Write-Host "Jenkins container not found. Creating and starting new container..."
    docker run -d --name $JenkinsContainerName -p $JenkinsPort:8080 -p 50000:50000 -v "$JenkinsVolume:/var/jenkins_home" jenkins/jenkins:lts
}

# --- 2. Show initial admin password if first run ---
Start-Sleep -Seconds 5
$adminPassFile = "$JenkinsVolume\secrets\initialAdminPassword"
if (Test-Path $adminPassFile) {
    $adminPass = Get-Content $adminPassFile
    Write-Host "`nInitial Jenkins admin password: $adminPass`n"
} else {
    Write-Host "`nJenkins already initialized or password file not found.`n"
}

# --- 3. Start ngrok in same PowerShell window ---
Write-Host "=== Starting ngrok to expose Jenkins ===`n"
Write-Host "Ngrok logs will appear below. Press Ctrl+C to stop ngrok after recording.`n"

# Start ngrok and wait a few seconds
Start-Process -FilePath $NgrokPath -ArgumentList "http $JenkinsPort --log=stdout" -NoNewWindow -PassThru | Out-Null
Start-Sleep -Seconds 5

# --- 4. Attempt to fetch ngrok public URL ---
try {
    $ngrokApi = Invoke-RestMethod -Uri http://127.0.0.1:4040/api/tunnels
    if ($ngrokApi.tunnels.Count -gt 0) {
        $publicUrl = $ngrokApi.tunnels[0].public_url
        Write-Host "`n✅ Ngrok public URL detected: $publicUrl"
        Write-Host "Use this URL for GitHub webhook payload URL:`n$publicUrl/github-webhook/`n"
    } else {
        Write-Host "⚠ Ngrok started but no tunnels found. Open http://127.0.0.1:4040 to check."
    }
} catch {
    Write-Host "⚠ Could not fetch ngrok URL automatically. Open http://127.0.0.1:4040 to see public URL."
}

# --- 5. Perform demo Git commit & push ---
Write-Host "=== Performing demo Git commit and push ===`n"
if (Test-Path $GitRepoPath) {
    Set-Location $GitRepoPath
    # Make a small change for demo
    Add-Content README.md "# $(Get-Date) Demo change"
    git add README.md
    git commit -m "$TestCommitMessage"
    git push
    Write-Host "`n✅ Demo Git commit pushed. Check GitHub, ngrok, Jenkins, and WebEx bot now."
} else {
    Write-Host "❌ Git repo folder not found: $GitRepoPath"
}

# --- 6. Recording Instructions ---
Write-Host "`n=== Recording Checklist ==="
Write-Host "1. GitHub commit page with timestamp 'now'"
Write-Host "2. Ngrok terminal shows POST /github-webhook/ (capture this in recording)"
Write-Host "3. Jenkins job auto-triggered"
Write-Host "4. Jenkins Console Output shows pytest passed"
Write-Host "5. WebEx space receives bot notification"
Write-Host "`nPress Enter to exit script after recording..."
Read-Host
