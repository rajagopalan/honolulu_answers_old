#!/bin/bash -e
gem install opendelivery bundler --no-ri --no-rdoc

ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'exploratory_check', '$accept'"
