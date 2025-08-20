import org.gradle.kotlin.dsl.DependencyHandlerScope

fun DependencyHandlerScope.localImplementation(dependency: String) {
    add("implementation", brukLocalDependencyHvisCompositeBuild(this, dependency))
}

fun DependencyHandlerScope.localTestImplementation(dependency: String) {
    add("testImplementation", brukLocalDependencyHvisCompositeBuild(this, dependency))
}

private fun brukLocalDependencyHvisCompositeBuild(scope: DependencyHandlerScope, dependency: String): String {
    val isCompositeBuild = scope.findProperty("compositeBuild") != null
    return if (isCompositeBuild) {
        dependency.replace(Regex(":[\\d+.]+$"), "")
    } else {
        dependency
    }
}

private fun DependencyHandlerScope.findProperty(name: String): Any? =
    (this as? org.gradle.api.Project)?.findProperty(name)
