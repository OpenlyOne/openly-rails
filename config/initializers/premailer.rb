# frozen_string_literal: true

Premailer::Rails.config.merge!(preserve_styles: true,
                               remove_ids: true,
                               remove_classes: true,
                               warn_level: Premailer::Warnings::SAFE,
                               adapter: :nokogiri)
