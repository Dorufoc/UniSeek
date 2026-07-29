import localUnitTest from './LocalUnit.test';
import foundationTest from './Foundation.test'
import recruiterResumeFilterTest from './RecruiterResumeFilter.test'
import applicationTabPolicyTest from './ApplicationTabPolicy.test'
import auditPoliciesTest from './AuditPolicies.test'
import recruiterDeadlineFormatterTest from './RecruiterDeadlineFormatter.test'
import chatUtilsTest from './chat/ChatUtils.test';
import chatComponentsTest from './chat/ChatComponents.test';
import chatWebSocketPolicyTest from './chat/ChatWebSocketPolicy.test';
import chatSendPolicyTest from './chat/ChatSendPolicy.test';
import regionPathBuilderTest from './RegionPathBuilder.test'
import fileTransferPolicyTest from './FileTransferPolicy.test'

export default function testsuite() {
  localUnitTest();
  foundationTest()
  recruiterResumeFilterTest()
  applicationTabPolicyTest()
  auditPoliciesTest()
  recruiterDeadlineFormatterTest()
  chatUtilsTest();
  chatComponentsTest();
  chatWebSocketPolicyTest();
  chatSendPolicyTest();
  regionPathBuilderTest();
  fileTransferPolicyTest();
}
