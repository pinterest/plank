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
 * Display ownership information for a list of files.
 */
final class ArcanistOwnersWorkflow extends ArcanistWorkflow {

    public function getWorkflowName() {
        return 'owners';
    }

    public function getCommandSynopses() {
        return phutil_console_format(<<<EOTEXT
      **owners** [__path__ ...]
EOTEXT
      );
    }

  public function getCommandHelp() {
    return phutil_console_format(<<<EOTEXT
          Supports: git, hg
          Display ownership information for a list of files.

          Without __paths__, the files changed in your local working copy will
          be used.
EOTEXT
      );
  }

  public function requiresConduit() {
    return true;
  }

  public function requiresAuthentication() {
    return true;
  }

  public function requiresRepositoryAPI() {
    return true;
  }

  public function getArguments() {
    return array(
      '*' => 'paths',
    );
  }

  public function getSupportedRevisionControlSystems() {
    return array('git', 'hg');
  }

  public function run() {
    $paths = $this->selectPathsForWorkflow(
      $this->getArgument('paths'),
      null,
      ArcanistRepositoryAPI::FLAG_UNTRACKED);

    $projects = array();

    foreach ($paths as $path) {
      $path_projects = $this->queryProjects($path);
      foreach ($path_projects as $project) {
        $phid = $project['phid'];
        if (!isset($projects[$phid])) {
          $projects[$phid] = array(
            'name' => $project['fields']['name'],
            'owners' => ipull($project['fields']['owners'], 'ownerPHID'),
          );
        }
        $projects[$phid]['paths'][] = $path;
      }
    }

    // Gather the owners across all of the discovered projects. Owners may
    // be either individual users or project tags.
    $owner_phids = array_mergev(ipull($projects, 'owners'));
    $owner_names = $this->resolveNames($owner_phids);

    foreach ($projects as $project) {
      $names = array_select_keys($owner_names, $project['owners']);

      echo phutil_console_format("**%s** (%s)\n",
        $project['name'],
        !empty($names) ? implode(', ', $names) : '<none>');

      asort($project['paths']);
      foreach ($project['paths'] as $path) {
        echo "  $path\n";
      }
    }
  }

  private function queryProjects($path) {
    $result = $this->getConduit()->callMethodSynchronous(
      'owners.search',
      array(
        'constraints' => array(
          'repositories' => array($this->getRepositoryPHID()),
          'paths' => array($path),
          'status' => array('active'),
        ),
      ));

    return idx($result, 'data', array());
  }

  private function resolveNames($phids) {
    $names = array();
    if ($phids) {
      $objects = $this->getConduit()->callMethodSynchronous(
        'phid.query',
        array(
          'phids' => $phids,
        ));

      foreach ($objects as $phid => $object) {
        $prefix = ($object['type'] == 'PROJ') ? '#' : '';
        $names[$phid] = $prefix.$object['name'];
      }
    }

    return $names;
  }
}
