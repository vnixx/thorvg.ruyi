# Publishing `io.github.vnixx:thorvg` to Maven Central

Repo wiring is done (`com.vanniktech.maven.publish` + POM + signing hooks).  
**Secrets never live in this repository** — only in `~/.gradle/gradle.properties` (or CI env).

Coordinates: **`io.github.vnixx:thorvg:<VERSION_NAME>`**  
Published file name: **`thorvg-<VERSION_NAME>.aar`**.

This AAR ships the ThorVG **C API** (`libthorvg.so` + Prefab headers). Higher-level wrappers belong in Ruyi.

---

## Order of operations

### 1. Register the Maven Central namespace

1. Sign in at [https://central.sonatype.com/](https://central.sonatype.com/).
2. **Namespaces** → claim **`io.github.vnixx`**.
3. Wait until the namespace shows as verified / ready.

### 2. Create a Portal user token

Central Portal → **Account** → **Generate User Token**.

### 3. Create & publish a GPG signing key

```bash
brew install gnupg
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
gpg --keyserver keyserver.ubuntu.com --send-keys <KEYID>
```

### 4. Put secrets in `~/.gradle/gradle.properties`

See `gradle/maven-publish.secrets.example`.

### 5. Confirm version

`android/gradle.properties` → `VERSION_NAME`.

### 6. Build & upload

```bash
cd android
./gradlew :thorvg:assembleRelease
./gradlew :thorvg:publishToMavenCentral
```

### 7. Publish on the website

Open [Deployments](https://central.sonatype.com/publishing) → **Publish**.
