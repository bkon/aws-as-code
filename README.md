# AwsAsCode

This gem is built upon a
great [cfndsl](https://github.com/stevenjack/cfndsl) CloudFormation
DSL language in order to automate routine tasks related to CF stack
updates:
- compilation of multiple associated templates;
- a sensible convention around the way compiled templates are uploaded
  and stored on S3;
- a simple wrapper around AWS SDK allowing you to apply stack changes
  immediately after they have been compiled and uploaded to S3.

This gem provides a command-line utility; normally you don't need to
use it as a library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_as_code'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_as_code

## Usage

`bundle exec aws-as-code [command] [option...]`

### Commands

#### `create`
Processes (compiles and uploads) CF templates and attempts to create a
new stack using them.

```
bundle exec aws-as-code create \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION" \
  --stack-params=ApiKey:KEY ApiSecret:SECRET
```

#### `update`
Processes (compiles and uploads) CF templates and applies changes to an
existing stack (keeping all existing stack parameters which are not explicitly
overridden in the command line)

```
bundle exec aws-as-code update \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION" \
  --stack-params=ApiSecret:NEWSECRET
```

#### `compile`
Compiles CF templates from `ruby-dir` using configuration from
`config-dir` and stores them locally in `json-dir`

```
bundle exec aws-as-code compile \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION"
```

Mainly used for debugging purposes.

#### `upload`
Uploads CF templates from `json-dir` to `bucket` on S3.

```
bundle exec aws-as-code upload \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION"
```

Mainly used for debugging purposes

#### `do-update`
Applies changes to the existing stack using currently uploaded templates.

```
bundle exec aws-as-code do-update \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION"
```

Mainly used for debugging purposes

#### `do-create`
Creates a new stack using templates already uploaded to S3

```
bundle exec aws-as-code do-create \
  --bucket=projectname-prod-cloudformation \
  --version="$VERSION"
```

Mainly used for debugging purposes

### Options

#### `--config-dir`

Directory with configuration files.

Default value: `cfn`

#### `--ruby-dir`

Directory with CloudFormation templates written in Ruby DSL

Default value: `cfn`

#### `--json-dir`

Directory to put compiled JSON CF templates to

Default value: `cfn-compiled`

#### `--bucket`

S3 bucket used to store compiled templates.

*Required*

#### `--template`

Filename of the stack root template.

Default value: `environment`

#### `--stack`

Name of the stack to create or update (also used as a part of the
uploaded template name to help distinguish stack templates compiled
from the same source but using different configurations)

Default value: `master`

#### `--stack-params`

A list of stack parameters in the key-value form.

```
--stack-params=ApiKey:KEY ApiSecret:SECRET
```

Optional. If not provided for `update` task, all parameters will be
kept as-is. If not provided for `create` task, no parameters will be
passed to the stack (if stack requires any parameters, then stack
creation will fail).

#### `--version`

Stack definition version. If you're using a version system, it's
highly recommended to use the latest commit hash as a version.

*Required*

## Configuration files

`aws-as-code` expects to find two configuration files in `config-dir`:
- parameters.yml
- settings.yml

### `parameters.yml`

Contains the list of stack parameters configurable through the
CloudFormation AWS console.

Format:

```
<PARAMETER NAME>:
  Type: "String" | "Number" | "CommaDelimitedList"
  Default: <DEFAULT VALUE>
  _ext:
    env: <ENVIRONMENT VARIABLE NAME>
    services: <LIST OF SERVICE NAMES THIS PARAMETER IS PASSED TO>
```

Example:

```
GoogleAnalyticsId:
  Type: String
  Default: UA-66947010-2
  _ext:
    env: GOOGLE_ANALYTICS_ID
    services:
      - web

MailerUrl:
  Type: String
  Default: test://localhost
  _ext:
    secure: true
    env: MAILER_URL
    services:
      - web
      - queue
```

Keep in mind that AWS has a
[hard cap of 60 parameters](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html)
available to your stack. If a value is not sensitive and doesn't need to be
reconfigured on the fly, consider using `settings.yml` instead!

From the example above, `GoogleAnalyticsId` *can* be moved to
`settings.yml`, while `MailerUrl` *cannot*, as it contains some
sensitive information such as SMTP username and password.

### `settings.yml`

Contains the list of non-sensitive environment-specific settings

Settings can be referenced from the tempalte definition using the
`setting('<SETTING NAME>')` DSL extension

Format:
```
<SETTING NAME>:
  <STACK NAME>: <VALUE>
  <STACK NAME>: <VALUE>
  _default: <DEFAULT VALUE>
```

Example:
```
es_instance_type:
  master: t2.small.elasticsearch
  _default: t2.small.elasticsearch
es_instance_count:
  master: 2
  _default: 1
web_tasks_count:
  master: 4
  _default: 1
```

## DSL extensions

### `env_ebs_options(env = nil)`
Generates a list of ElasticBeanstalk confugration options passing the
list of stack parameters to the ElasticBeanstalk environment.

Example:

```
ElasticBeanstalk_Environment "Service" do
  Description "Sample app"
  ApplicationName Ref "Application"
  VersionLabel Ref "CurrentVersion"
  OptionSettings [
    {
      Namespace: "aws:elasticbeanstalk:environment",
      OptionName: "EnvironmentType",
      Value: "SingleInstance"
    }
  ] + env_ebs_options("web")
  SolutionStackName "SOLUTION"
end
```

### `env_passthrough(env = nil)`
Generates a list of stack parameters passing the list input parameters specific
to a selected environment `env` to a nested stack.

Example:

```
CloudFormation_Stack "Services" do
  Parameters Hash[
               VPC: FnGetAtt("Network", "Outputs.VPC"),
             ].merge(env_passthrough)
  TemplateURL template_url "services"
  TimeoutInMinutes 20
end
```

### `inputs(env = nil)`
Generates a list of stack input declarations for the environment `env`.

Example:

```
CloudFormation do
  inputs("web")

  Parameter "SubnetA" do
    String()
  end
  ...
```

### `params(env = nil)`
Returns a list of parameters for environment `env`

### `setting(key)`
Returns the value of the setting `key` from `settings.yml`

Example:

```
Resource "Lambda" do
  Type "AWS::Lambda::Function"
  Property "Description", "Sample lambda"
  Property "Handler", "main.handler"
  Property "Code",
           S3Bucket: setting("lambda_source"),
           S3Key: FnJoin(
             "",
             [
               "lambda/", ENV["VERSION"], ".zip"
             ]
           )
  Property "Runtime", "nodejs6.10"
  Property "Timeout", "3"
  Property "Role", setting("role")
end
```

### `template_url`

Returns a full S3 URL (including dynamically generated version) of another template.

Example:

```
CloudFormation do
  inputs

  CloudFormation_Stack "Network" do
    TemplateURL template_url "network"
    TimeoutInMinutes 10
  end
end
```

## Examples

### Deploying stack changes from CircleCI

Assuming that AWS credentials (secret, key and default region) are
available in the build environment and this user has all the required
permissions to perform the required stack updates.

#### `circle.yml`
```
deployment:
  production:
    branch: master
    commands:
      - >
        bundle exec aws-as-code update \
          --template=environment \
          --config-dir=core \
          --ruby-dir=core/cfn \
          --json-dir=tmp/cfn \
          --bucket=projectname-prod-cloudformation \
          --stack="$CIRCLE_BRANCH" \
          --version="$CIRCLE_SHA1"
```
