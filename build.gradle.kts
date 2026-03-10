// Call the tasks of the included builds

for (taskName in listOf<String>("clean", "build", "assemble", "check")) {
    tasks.register(taskName) {
        dependsOn(gradle.includedBuilds.map {
            it.task(":${taskName}")
        })
    }
}
