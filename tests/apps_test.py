# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
import unittest
from runner import Runner


class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """

            provider "aws" {
              region = "eu-west-2"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "apps" {
              source = "./mymodule"

              providers = {
                aws = "aws"
              }

              cidr_block                      = "10.1.0.0/16"
              public_subnet_cidr_block        = "10.1.0.0/24"
              ad_subnet_cidr_block            = "10.1.0.0/24"
              az                              = "eu-west-2a"
              az2                             = "eu-west-2b"
              #adminpassword                   = "1234"
              ad_aws_ssm_document_name        = "1234"
              #ad_writer_instance_profile_name = "1234"
              naming_suffix                   = "preprod-dq"
              #haproxy_private_ip              = "1.2.3.3"
              #haproxy_private_ip2             = "1.2.3.4"

              s3_bucket_name = {
                archive_log  = "abcd"
                archive_data = "abcd"
                working_data = "abcd"
                landing_data = "abcd"
                airports_archive = "abcd"
                airports_working = "abcd"
                airports_internal = "abcd"
                oag_archive = "abcd"
                acl_archive = "abcd"
                reference_data = "abcd"
                reference_data_archive = "abcd"
                reference_data_internal = "abcd"
                api_archive = "abcd"
                oag_internal = "abcd"
                oag_transform = "abcd"
                acl_internal = "abcd"
                api_internal = "abcd"
                consolidated_schedule = "abcd"
                api_record_level_scoring = "abcd"
                raw_file_retrieval_index = "abcd"
                cross_record_scored = "abcd"
                drt_working = "abcd"
                fms_working = "abcd"
                reporting_internal_working = "abcd"
                carrier_portal_working = "abcd"
              }

              s3_bucket_acl = {
                archive_log  = "abcd"
                archive_data = "abcd"
                working_data = "abcd"
                landing_data = "abcd"
                airports_archive = "abcd"
                airports_working = "abcd"
                airports_internal = "abcd"
                oag_archive = "abcd"
                acl_archive = "abcd"
                reference_data = "abcd"
                reference_data_archive = "abcd"
                reference_data_internal = "abcd"
                api_archive = "abcd"
                oag_internal = "abcd"
                oag_transform = "abcd"
                acl_internal = "abcd"
                api_internal = "abcd"
                consolidated_schedule = "abcd"
                api_record_level_scoring = "abcd"
                raw_file_retrieval_index = "abcd"
                cross_record_scored = "abcd"
                drt_working = "abcd"
                fms_working = "abcd"
                reporting_internal_working = "abcd"
                carrier_portal_working = "abcd"
              }

              route_table_cidr_blocks     = {
                peering_cidr = "1234"
                ops_cidr     = "10.2.0.0/24"
                acp_vpn      = "1234"
                acp_prod     = "1234"
                acp_ops      = "1234"
                acp_cicd     = "1234"
              }
              vpc_peering_connection_ids  = {
                peering_to_peering = "1234"
                peering_to_ops     = "1234"
              }
              ad_sg_cidr_ingress = [
                "1.2.0.0/16",
                "1.2.0.0/16",
                "1.2.0.0/16"
              ]
            }
        """
        self.result = Runner(self.snippet).result

    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test_apps_vpc_cidr_block(self):
        self.assertEqual(self.result['apps']["aws_vpc.appsvpc"]["cidr_block"], "10.1.0.0/16")

    def test_apps_public_cidr(self):
        self.assertEqual(self.result['apps']["aws_subnet.public_subnet"]["cidr_block"], "10.1.0.0/24")

    def test_az_public_subnet(self):
        self.assertEqual(self.result['apps']["aws_subnet.public_subnet"]["availability_zone"], "eu-west-2a")

    def test_name_suffix_ari(self):
        self.assertEqual(self.result['apps']["aws_internet_gateway.AppsRouteToInternet"]["tags.Name"], "igw-apps-preprod-dq")

    def test_name_suffix_appsvpc(self):
        self.assertEqual(self.result['apps']["aws_vpc.appsvpc"]["tags.Name"], "vpc-apps-preprod-dq")

    def test_name_suffix_public_subnet(self):
        self.assertEqual(self.result['apps']["aws_subnet.public_subnet"]["tags.Name"], "public-subnet-apps-preprod-dq")

    def test_name_suffix_ad_subnet(self):
        self.assertEqual(self.result['apps']["aws_subnet.ad_subnet"]["tags.Name"], "ad-subnet-apps-preprod-dq")

    def test_name_suffix_route_table(self):
        self.assertEqual(self.result['apps']["aws_route_table.apps_route_table"]["tags.Name"], "route-table-apps-preprod-dq")

    def test_name_suffix_public_route(self):
        self.assertEqual(self.result['apps']["aws_route_table.apps_public_route_table"]["tags.Name"], "public-route-table-apps-preprod-dq")

    def test_name_suffix_appsnatgw(self):
        self.assertEqual(self.result['apps']["aws_nat_gateway.appsnatgw"]["tags.Name"], "natgw-apps-preprod-dq")

    def test_name_suffix_archive_log(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.log_archive_bucket"]["tags.Name"], "s3-log-archive-bucket-apps-preprod-dq")

    def test_name_suffix_data_archive_log(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.data_archive_bucket"]["tags.Name"], "s3-data-archive-bucket-apps-preprod-dq")

    def test_name_suffix_data_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.data_working_bucket"]["tags.Name"], "s3-data-working-bucket-apps-preprod-dq")

    def test_name_suffix_airports_archive(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.airports_archive_bucket"]["tags.Name"], "dq-airports-archive-apps-preprod-dq")

    def test_name_suffix_airports_internal(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.airports_internal_bucket"]["tags.Name"], "dq-airports-internal-apps-preprod-dq")

    def test_name_suffix_airports_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.airports_working_bucket"]["tags.Name"], "dq-airports-working-apps-preprod-dq")

    #def test_name_suffix_nats_iam_group(self):
    #    self.assertEqual(self.result['apps']["aws_iam_group.nats"]["name"], "iam-group-nats-apps-preprod-dq")

    #def test_name_suffix_nats_iam_group_membership(self):
    #    self.assertEqual(self.result['apps']["aws_iam_group_membership.nats"]["name"], "iam-group-membership-nats-apps-preprod-dq")

    #def test_name_suffix_nats_iam_group_policy(self):
    #    self.assertEqual(self.result['apps']["aws_iam_group_policy.nats"]["name"], "group-policy-nats-apps-preprod-dq")

    #def test_name_suffix_nats_iam_user(self):
    #    self.assertEqual(self.result['apps']["aws_iam_user.nats"]["name"], "iam-user-nats-apps-preprod-dq")

    def test_name_suffix_oag_archive(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.oag_archive_bucket"]["tags.Name"], "dq-oag-archive-apps-preprod-dq")

    def test_name_suffix_oag_internal(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.oag_internal_bucket"]["tags.Name"], "dq-oag-internal-apps-preprod-dq")

    def test_name_suffix_oag_transform(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.oag_transform_bucket"]["tags.Name"], "dq-oag-transform-apps-preprod-dq")

    def test_name_suffix_acl_archive(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.acl_archive_bucket"]["tags.Name"], "dq-acl-archive-apps-preprod-dq")

    def test_name_suffix_acl_internal(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.acl_internal_bucket"]["tags.Name"], "dq-acl-internal-apps-preprod-dq")

    def test_name_suffix_consolidated_schedule(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.consolidated_schedule_bucket"]["tags.Name"], "dq-consolidated-schedule-apps-preprod-dq")

    def test_name_suffix_api_record_level_scoring(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.api_record_level_scoring_bucket"]["tags.Name"], "dq-api-record-level-scoring-apps-preprod-dq")

    def test_name_suffix_raw_file_retrieval_index(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.raw_file_retrieval_index_bucket"]["tags.Name"], "dq-raw-file-retrieval-index-apps-preprod-dq")

    def test_name_suffix_cross_record_scored(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.cross_record_scored_bucket"]["tags.Name"], "dq-cross-record-scored-apps-preprod-dq")

    def test_name_suffix_drt_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.drt_working_bucket"]["tags.Name"], "dq-drt-working-apps-preprod-dq")

    def test_name_suffix_fms_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.fms_working_bucket"]["tags.Name"], "dq-fms-working-apps-preprod-dq")

    def test_name_suffix_reporting_internal_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.reporting_internal_working_bucket"]["tags.Name"], "dq-reporting-internal-working-apps-preprod-dq")

    def test_name_suffix_carrier_portal_working(self):
        self.assertEqual(self.result['apps']["aws_s3_bucket.carrier_portal_working_bucket"]["tags.Name"], "dq-carrier-portal-working-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_lambda_function.lambda_athena"]["tags.Name"], "lambda-athena-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_iam_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_iam_role.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_ssm_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_ssm_parameter.lambda_trigger"]["tags.Name"], "ssm-lambda-trigger-enabled-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_iam_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_iam_role.lambda_athena"]["tags.Name"], "lambda-athena-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_log_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_cloudwatch_log_group.lambda_athena"]["tags.Name"], "lambda-athena-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_sfn_state_machine(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_sfn_state_machine.sfn_state_machine"]["tags.Name"], "sfn-state-machine-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_lambda_function.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_input_pipeline_log_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_input_pipeline']["aws_cloudwatch_log_group.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-input-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_iam_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_iam_role.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_iam_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_iam_role.lambda_athena"]["tags.Name"], "lambda-athena-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_iam_lambda_rds(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_iam_role.lambda_rds"]["tags.Name"], "iam-lambda-rds-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_step_function_exec(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_iam_role.step_function_exec"]["tags.Name"], "step-function-exec-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_lambda_trigger_enabled(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_ssm_parameter.lambda_trigger_enabled"]["tags.Name"], "ssm-lambda-trigger-enabled-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_lambda_function.lambda_athena"]["tags.Name"], "lambda-athena-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_lambda_function.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_lambda_rds(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_lambda_function.lambda_rds"]["tags.Name"], "lambda-rds-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_log_lambda_athena(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_cloudwatch_log_group.lambda_athena"]["tags.Name"], "lambda-athena-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_log_lambda_rds(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_cloudwatch_log_group.lambda_rds"]["tags.Name"], "logs-lambda-rds-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_log_lambda_trigger(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_cloudwatch_log_group.lambda_trigger"]["tags.Name"], "lambda-trigger-airports-apps-preprod-dq")

    def test_name_suffix_airports_pipeline_sfn_state_machine(self):
        self.assertEqual(self.result['apps']['airports_pipeline']["aws_sfn_state_machine.sfn_state_machine"]["tags.Name"], "sfn-state-machine-airports-apps-preprod-dq")

    def test_name_suffix_rds_deploy_iam_lambda_rds(self):
        self.assertEqual(self.result['apps']['rds_deploy']["aws_iam_role.lambda_rds"]["tags.Name"], "iam-lambda-rds-deploy-apps-preprod-dq")

    def test_name_suffix_rds_deploy_lambda_function(self):
        self.assertEqual(self.result['apps']['rds_deploy']["aws_lambda_function.lambda_rds"]["tags.Name"], "lambda-rds-deploy-apps-preprod-dq")

    def test_name_suffix_rds_deploy_cloudwatch_log_group(self):
        self.assertEqual(self.result['apps']['rds_deploy']["aws_cloudwatch_log_group.lambda_rds"]["tags.Name"], "lambda-rds-deploy-apps-preprod-dq")

if __name__ == '__main__':
    unittest.main()
