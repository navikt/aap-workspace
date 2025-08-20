import java.io.File
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.Exec

plugins {
    id("base")
}

// Aggregate tasks for all included builds
val included = gradle.includedBuilds

val isWindows = System.getProperty("os.name").lowercase().contains("win")
fun wrapperPath(dir: File): String =
    if (isWindows) File(dir, "gradlew.bat").absolutePath else File(dir, "gradlew").absolutePath

// Register one Exec task per included build for build
val perBuildBuildTasks = included.map { ib ->
    tasks.register<Exec>("ib_${ib.name}_build") {
        workingDir = ib.projectDir
        if (!isWindows) {
            doFirst {
                val w = file(wrapperPath(ib.projectDir))
                if (!w.canExecute()) w.setExecutable(true)
            }
        }
        commandLine(wrapperPath(ib.projectDir), "build")
    }
}

// Register one Exec task per included build for test (fallback to check, then build)
val perBuildTestTasks = included.map { ib ->
    tasks.register<Exec>("ib_${ib.name}_test") {
        workingDir = ib.projectDir
        if (!isWindows) {
            doFirst {
                val w = file(wrapperPath(ib.projectDir))
                if (!w.canExecute()) w.setExecutable(true)
            }
            val w = wrapperPath(ib.projectDir)
            commandLine("bash", "-lc", "'$w' test || '$w' check")
        } else {
            val w = wrapperPath(ib.projectDir)
            commandLine("cmd", "/c", "\"$w test || $w check\"")
        }
    }
}

// Aggregate tasks
val buildAll = tasks.register("buildAll") { dependsOn(perBuildBuildTasks) }

// Hook root lifecycle tasks
tasks.named("build") { dependsOn(buildAll) }

// Root test runs tests across all included builds
tasks.register("test") { dependsOn(perBuildTestTasks) }

// Robust clean: delete all build/ directories under each included build recursively
tasks.named<Delete>("clean") {
    val dirsToDelete = included.flatMap { ib ->
        ib.projectDir.walkTopDown()
            .onEnter { dir ->
                val name = dir.name
                name != ".gradle" && name != ".git" && name != ".idea" && name != "node_modules"
            }
            .filter { it.isDirectory && it.name == "build" }
            .toList()
    }
    delete(dirsToDelete)
}
