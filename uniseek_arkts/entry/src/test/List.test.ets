import localUnitTest from './LocalUnit.test';
import foundationTest from './Foundation.test'
import recruiterResumeFilterTest from './RecruiterResumeFilter.test'
import applicationTabPolicyTest from './ApplicationTabPolicy.test'
import auditPoliciesTest from './AuditPolicies.test'

export default function testsuite() {
  localUnitTest();
  foundationTest()
  recruiterResumeFilterTest()
  applicationTabPolicyTest()
  auditPoliciesTest()
}
