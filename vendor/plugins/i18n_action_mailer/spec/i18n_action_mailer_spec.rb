require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class SomeMailer < ActionMailer::Base
  def some_mail(locale)
    set_locale locale

    subject t('some_mail.title', :default => "default subject")
    recipients "some_mail@example.com"
    from "from@example.com"
  end
end

describe "I18nActionMailer" do
  it "should render en template" do
    mail = SomeMailer.create_some_mail("en")
    mail.body.should =~ /Hi! English/
  end

  it "should render ja template" do
    mail = SomeMailer.create_some_mail("ja")
    mail.body.should =~ /こんにちは、日本語/
  end

  describe "When I18n locale is set as ja" do
    before do
      I18n.locale = "ja"
    end
    it "should render en template" do
      mail = SomeMailer.create_some_mail('en')
      mail.body.should =~ /Hi! English/
    end
    it "should render ja template" do
      mail = SomeMailer.create_some_mail('ja')
      mail.body.should =~ /こんにちは、日本語/
    end
  end
end
