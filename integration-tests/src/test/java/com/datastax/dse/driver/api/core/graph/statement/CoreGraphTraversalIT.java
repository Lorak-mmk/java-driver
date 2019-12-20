/*
 * Copyright DataStax, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.datastax.dse.driver.api.core.graph.statement;

import com.datastax.dse.driver.api.core.DseSession;
import com.datastax.dse.driver.api.core.graph.GraphTestSupport;
import com.datastax.dse.driver.api.core.graph.SampleGraphScripts;
import com.datastax.dse.driver.api.core.graph.ScriptGraphStatement;
import com.datastax.dse.driver.api.core.graph.SocialTraversalSource;
import com.datastax.dse.driver.api.testinfra.session.DseSessionRule;
import com.datastax.oss.driver.api.testinfra.DseRequirement;
import com.datastax.oss.driver.api.testinfra.ccm.CustomCcmRule;
import org.apache.tinkerpop.gremlin.process.traversal.dsl.graph.GraphTraversalSource;
import org.apache.tinkerpop.gremlin.structure.util.empty.EmptyGraph;
import org.junit.BeforeClass;
import org.junit.ClassRule;
import org.junit.rules.RuleChain;
import org.junit.rules.TestRule;

@DseRequirement(min = "6.8.0", description = "DSE 6.8.0 required for Core graph support")
public class CoreGraphTraversalIT extends GraphTraversalITBase {

  private static final CustomCcmRule CCM_RULE = GraphTestSupport.CCM_BUILDER_WITH_GRAPH.build();

  private static final DseSessionRule SESSION_RULE =
      GraphTestSupport.getCoreGraphSessionBuilder(CCM_RULE).build();

  @ClassRule
  public static final TestRule CHAIN = RuleChain.outerRule(CCM_RULE).around(SESSION_RULE);

  private final GraphTraversalSource graphTraversalSource =
      EmptyGraph.instance().traversal().with("allow-filtering");
  private final SocialTraversalSource socialTraversalSource =
      EmptyGraph.instance().traversal(SocialTraversalSource.class).with("allow-filtering");

  @BeforeClass
  public static void setupSchema() {
    SESSION_RULE.session().execute(ScriptGraphStatement.newInstance(SampleGraphScripts.CORE_GRAPH));
  }

  @Override
  protected DseSession session() {
    return SESSION_RULE.session();
  }

  @Override
  protected boolean isGraphBinary() {
    return true;
  }

  @Override
  protected CustomCcmRule ccmRule() {
    return CCM_RULE;
  }

  @Override
  protected GraphTraversalSource graphTraversalSource() {
    return graphTraversalSource;
  }

  @Override
  protected SocialTraversalSource socialTraversalSource() {
    return socialTraversalSource;
  }
}