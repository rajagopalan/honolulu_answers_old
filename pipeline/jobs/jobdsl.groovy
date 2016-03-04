static Closure pipelineConfig(String task, String stage) {
    return { project ->
        def pipelineConfig = project / 'properties' / 'se.diabol.jenkins.pipeline.PipelineProperty'
        pipelineConfig << { stageName stage }
        pipelineConfig << { taskName task }
    }
}

// pipelines is a map of maps of arrays
// pipelines is a map of pipeline names mapped to maps of stage names mapped to jobs

def create_view(pipeline, triggerjob) {
  view {
    name = pipeline
    configure { view ->
      view.name = 'se.diabol.jenkins.pipeline.DeliveryPipelineView'
      (view / 'name').setValue("${pipeline} View")
      (view / 'noOfPipelines').setValue(3)
      (view / 'noOfColumns').setValue(1)
      (view / 'sorting').setValue("none")
      (view / 'showAvatars').setValue("false")
      (view / 'updateInterval').setValue(2)
      (view / 'showChanges').setValue("false")
      (view / 'showAggregatedPipeline').setValue("false")
      (view / 'componentSpecs' / 'se.diabol.jenkins.pipeline.DeliveryPipelineView_-ComponentSpec' / 'name').setValue(pipeline)
      (view / 'componentSpecs' / 'se.diabol.jenkins.pipeline.DeliveryPipelineView_-ComponentSpec' / 'firstJob').setValue("${triggerjob}-dsl")
    }
  }
}

def pipelines =  [
  "Continuous Delivery Pipeline":[
    "commit":["trigger", "commit", "run-static-security-tests", "run-code-quality-analysis"],
    "acceptance": ["create-environment-acceptance", "run-infrastructure-tests", "run-integration-tests", "terminate-environment-acceptance"],
    "exploratory" : ["approve-reject-exploratory"],
    "capacity" : ["launch-environment-capacity", "performance-testing", "load-testing", "stress-testing", "penetration-testing"],
    "production" : ["approve-reject-prod", "launch-prod-environment", "blue-green-deployment"]
  ]
]

pipelines.each { pipeline, stages ->
  stageList = stages.keySet().toArray()
  create_view(pipeline, stages[stageList[0]].first())

  // the data structure we define the pipelines in is useful for humans to read, but a pain to look-forward through. Translate to something easier to code around.
    def joblist = []
    stages.each { stage, jobs ->
      jobs.each { job ->
        joblist.add([job, stage])
      }
    }

    [*joblist, null].collate(2, 1, false).each { currentJob, nextJob ->
    jobName = currentJob[0]
    nextJobName = nextJob == null ? null : nextJob[0]
    stage = currentJob[1]

    job {
      println "configuring ${jobName}'s pipeline config: ${jobName} / ${stage}"
      configure pipelineConfig(jobName, stage)
      name "${jobName}-dsl"
      multiscm {
        git("https://github.com/rajagopalan/honolulu_answers_cookbooks.git", "master") { node ->
          node / skipTag << "true"
        }
        git("https://github.com/rajagopalan/honolulu_answers.git", "master") { node ->
          node / skipTag << "true"
        }
      }
      if (jobName.equals("trigger")) {
        triggers {
          scm("* * * * *")
        }
      }
      steps {
        shell("pipeline/${jobName}.sh")
        if (nextJobName != null) {
          downstreamParameterized {
            trigger ("${nextJobName}-dsl", "ALWAYS"){
              currentBuild()
              propertiesFile("environment.txt")
            }
          }
        }
      }
      wrappers {
        rvm("2.0.0")
      }
      publishers {
        extendedEmail("nextgenops@cdsimplified.com", "\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!", """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

        Check console output at \$BUILD_URL to view the results.""") {
          trigger("Failure")
          trigger("Fixed")
        }
      }
    }
  }
}

// Special configuration pipeline jobs
job {
 name "preprod-control"
  parameters {
    choiceParam("accept", ["reject", "accept"], "Select accept if the environment should progress through a production deployment")
    stringParam("pipeline_instance_id", "", "This is the id of the pipeline you wish to accept or reject")
  }
  multiscm {
   git("https://github.com/rajagopalan/honolulu_answers_cookbooks.git", "master") { node ->
     node / skipTag << "true"
   }
   git("https://github.com/rajagopalan/honolulu_answers.git", "master") { node ->
     node / skipTag << "true"
   }
 }
 steps {
   shell("pipeline/preprod-control.sh")
 }
 wrappers {
   rvm("2.2.0")
 }
}

job {
 name "exploratory-control"
  parameters {
    choiceParam("accept", ["reject", "accept"], "Select accept if the environment passes user accetance testing")
    stringParam("pipeline_instance_id", "", "This is the id of the pipeline you wish to accept or reject")
  }
  multiscm {
   git("https://github.com/rajagopalan/honolulu_answers_cookbooks.git", "master") { node ->
     node / skipTag << "true"
   }
   git("https://github.com/rajagopalan/honolulu_answers.git", "master") { node ->
     node / skipTag << "true"
   }
 }
 steps {
   shell("pipeline/exploratory-control.sh")
 }
 wrappers {
   rvm("2.2.0")
 }
}


// self service jobs
job {
  name "self-service-create-dsl"
  parameters {
    stringParam("email", "", "The email address of the owner of the environment.")
    stringParam("SHA", "HEAD", "The Git SHA of the revision you want to deploy. The default is HEAD, which will just get the latest code from the repo.")
  }
  multiscm {
    git("https://github.com/rajagopalan/honolulu_answers_cookbooks.git", "master") { node ->
      node / skipTag << "true"
    }
    git("https://github.com/rajagopalan/honolulu_answers.git", "master") { node ->
      node / skipTag << "true"
    }
  }
  steps {
    shell("pipeline/self-service-create.sh")
  }
  wrappers {
    rvm("2.0.0")
  }
  publishers {
    extendedEmail("\$email", "Your self service environment is ready.", """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

    Check console output at \$BUILD_URL to view the results.""") {
      trigger("Success")
    }
  }
}

job {
  name "self-service-delete-dsl"
   parameters {
    stringParam("stack_name", "", "The CloudFormation stack name to clean up")
   }
   multiscm {
    git("https://github.com/rajagopalan/honolulu_answers_cookbooks.git", "master") { node ->
      node / skipTag << "true"
    }
    git("https://github.com/rajagopalan/honolulu_answers.git", "master") { node ->
      node / skipTag << "true"
    }
  }
  steps {
    shell("pipeline/self-service-delete.sh")
  }
  wrappers {
    rvm("2.0.0")
  }
}
