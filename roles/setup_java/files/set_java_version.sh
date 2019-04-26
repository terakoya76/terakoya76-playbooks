# $1=JAVA_VERSION like 1.8,11,12
set_java() {
  export JAVA_HOME=$(/usr/libexec/java_home -v $1)
  PATH=${JAVA_HOME}/bin:${PATH}
}
