<?php
/**
 * Copyright 2016 Pinterest, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Lints Apache Thrift IDL files using the "thrift" compiler.
 */
final class ApacheThriftLinter extends ArcanistExternalLinter {

  private $generators = array();
  private $includes = array();
  private $tmpdir = null;

  public function getInfoName() {
    return 'Apache Thrift Linter';
  }

  public function getInfoDescription() {
    return pht('Validates Thrift files');
  }

  public function getInfoURI() {
    return 'https://thrift.apache.org/';
  }

  public function getLinterName() {
    return 'THRIFT';
  }

  public function getLinterConfigurationName() {
    return 'thrift';
  }

  public function getLinterConfigurationOptions() {
    $options = array(
      'thrift.generators' => array(
        'type' => 'list<string>',
        'help' => pht("List of code generators to use."),
      ),
      'thrift.includes' => array(
        'type' => 'optional list<string>',
        'help' => pht('List of directories searched for include directives.'),
      ),
    );

    return $options + parent::getLinterConfigurationOptions();
  }

  public function setLinterConfigurationValue($key, $value) {
    switch ($key) {
      case 'thrift.generators':
        if (empty($value)) {
          throw new Exception(pht('At least one generator must be specified.'));
        }
        $this->generators = $value;
        return;
      case 'thrift.includes':
        $this->includes = $value;
        return;
    }

    return parent::setLinterConfigurationValue($key, $value);
  }

  public function getDefaultBinary() {
    return 'thrift';
  }

  public function getVersion() {
    list($err, $stdout, $stderr) = exec_manual(
      '%C -version',
      $this->getExecutableCommand());

    $matches = array();
    if (preg_match('/^Thrift version (?P<version>.*)$/', $stdout, $matches)) {
      return $matches['version'];
    } else {
      return false;
    }
  }

  public function getInstallInstructions() {
    return pht(
      'Install thrift using `%s` (OS X) or `%s` (Linux).',
      'brew install thrift',
      'apt-get install thrift');
  }

  public function shouldExpectCommandErrors() {
    return true;
  }

  protected function getMandatoryFlags() {
    if ($this->tmpdir == null) {
      $this->tmpdir = Filesystem::createTemporaryDirectory('arc-lint-thrift-');
    }

    $flags = array('-out', $this->tmpdir);
    foreach ($this->generators as $generator) {
      array_push($flags, '--gen', $generator);
    }
    foreach ($this->includes as $dir) {
      array_push($flags, '-I', $dir);
    }
    return $flags;
  }

  protected function canCustomizeLintSeverities() {
    return false;
  }

  protected function didResolveLinterFutures(array $futures) {
    if ($this->tmpdir != null) {
        Filesystem::remove($this->tmpdir);
        $this->tmpdir = null;
    }

    return parent::didResolveLinterFutures($futures);
  }

  protected function parseLinterOutput($path, $err, $stdout, $stderr) {
    $lines = phutil_split_lines($err ? $stderr : $stdout, false);
    $regex = '/^\[(?P<severity>[A-Z]+):(?P<path>.*):(?P<lineno>\d+)\]\s+(?P<message>[^\(].*)$/';

    $messages = array();
    foreach ($lines as $line) {
      $matches = null;
      if (preg_match($regex, $line, $matches)) {
        // Older versions of Thrift (<0.9) generate output for included files.
        // Ignore any entries for files other than the active path.
        if (!Filesystem::pathsAreEquivalent($path, $matches['path'])) {
          continue;
        }

        $message = new ArcanistLintMessage();
        $message->setPath($path);
        $message->setLine($matches['lineno']);
        $message->setCode($this->getLinterName());
        $message->setName($this->getLinterName());
        $message->setDescription($matches['message']);
        $message->setSeverity($this->getMatchSeverity($matches['severity']));
        $messages[] = $message;
      }
    }

    return array_unique($messages, SORT_REGULAR);
  }

  private function getMatchSeverity($name) {
    $map = array(
      'ERROR'    => ArcanistLintSeverity::SEVERITY_ERROR,
      'FAILURE'  => ArcanistLintSeverity::SEVERITY_ERROR,
      'WARNING'  => ArcanistLintSeverity::SEVERITY_WARNING,
    );

    if (array_key_exists($name, $map)) {
       return $map[$name];
    }

    return ArcanistLintSeverity::SEVERITY_ERROR;
  }
}
