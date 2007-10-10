# ActionController::Base.send :include, Rhalo3stats::ControllerHelpers
ActiveRecord::Base.send(:include, Rhalo3stats::ModelExtensions)