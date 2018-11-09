# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentDownloader, type: :model do
  subject(:downloader) { described_class.new(attributes) }

  let(:attributes) do
    {
      repository: repository,
      remote_file_id: remote_file_id,
      remote_content_version_id: remote_content_version_id
    }
  end
  let(:repository) { create :vcs_repository }
  let(:remote_file_id) { 'remote-id' }
  let(:remote_content_version_id) { 'content-vers' }

  describe '#plain_text', :vcr do
    before  { prepare_google_drive_test }
    after   { tear_down_google_drive_test }
    after   { downloader.done }

    subject(:plain_text) { downloader.plain_text }

    let(:remote_file) do
      file_sync_class.upload(
        name: 'document',
        parent_id: google_drive_test_folder_id,
        file: file,
        mime_type: Henkei.new(file).mimetype.content_type
      )
    end
    let(:downloader) { described_class.new(remote_file_id: remote_file.id) }
    let(:file_sync_class) { Providers::GoogleDrive::FileSync }
    let(:file) { File.open(path_to_file_fixtures.join(file_name)) }
    let(:path_to_file_fixtures) do
      Rails.root.join('spec', 'support', 'fixtures', 'files')
    end

    context 'when file is a Google Doc' do
      let(:remote_file) do
        file_sync_class.create(
          name: 'word document.docx',
          parent_id: google_drive_test_folder_id,
          mime_type: Providers::GoogleDrive::MimeType.document
        )
      end

      before { remote_file.update_content('This is a sentence') }

      it { is_expected.to eq 'This is a sentence' }
    end

    context 'when file is a .docx document' do
      let(:file_name) { 'file.docx' }

      it do
        is_expected.to eq(
          <<~TEXT.gsub(/(?<!\n)\n(?!\n)/, ' ').strip
            Business Plan Template for a Startup Business

            A startup business plan serves several purposes. It can help
            convince investors or lenders to finance your business. It can
            persuade partners or key employees to join your company. Most
            importantly, it serves as a roadmap guiding the launch and growth
            of your new business.

            Writing a business plan is an opportunity to carefully think through
            every step of starting your company so you can prepare for success.
            This is your chance to discover any weaknesses in your business
            idea, identify opportunities you may not have considered, and plan
            how you will deal with challenges that are likely to arise. Be
            honest with yourself as you work through your business plan. Don’t
            gloss over potential problems; instead, figure out solutions.

            A good business plan is clear and concise. A person outside of your
            industry should be able to understand it. Avoid overusing industry
            jargon or terminology.

            Most of the time involved in writing your plan should be spent
            researching and thinking. Make sure to document your research,
            including the sources of any information you include.

            Avoid making unsubstantiated claims or sweeping statements.
            Investors, lenders and others reading your plan will want to see
            realistic projections and expect your assumptions to be supported
            with facts.

            This template includes instructions for each section of the business
            plan, followed by corresponding fillable worksheet/s.

            The last section in the instructions, “Refining Your Plan,” explains
            ways you may need to modify your plan for specific purposes, such as
            getting a bank loan, or for specific industries, such as retail.

            Proofread your completed plan (or have someone proofread it for you)
            to make sure it’s free of spelling and grammatical errors and that
            all figures are accurate.
          TEXT
        )
      end
    end

    context 'when file is a PDF' do
      let(:file_name) { 'file.pdf' }

      it do
        expect(plain_text.squish).to eq(
          <<~TEXT.squish
            Business Plan Template for a Startup Business

            A startup business plan serves several purposes. It can help
            convince investors or lenders to finance your business. It can
            persuade partners or key employees to join your company. Most
            importantly, it serves as a roadmap guiding the launch and growth
            of your new business.

            Writing a business plan is an opportunity to carefully think through
            every step of starting your company so you can prepare for success.
            This is your chance to discover any weaknesses in your business
            idea, identify opportunities you may not have considered, and plan
            how you will deal with challenges that are likely to arise. Be
            honest with yourself as you work through your business plan. Don’t
            gloss over potential problems; instead, figure out solutions.

            A good business plan is clear and concise. A person outside of your
            industry should be able to understand it. Avoid overusing industry
            jargon or terminology.

            Most of the time involved in writing your plan should be spent
            researching and thinking. Make sure to document your research,
            including the sources of any information you include.

            Avoid making unsubstantiated claims or sweeping statements.
            Investors, lenders and others reading your plan will want to see
            realistic projections and expect your assumptions to be supported
            with facts.

            This template includes instructions for each section of the business
            plan, followed by corresponding fillable worksheet/s.

            The last section in the instructions, “Refining Your Plan,” explains
            ways you may need to modify your plan for specific purposes, such as
            getting a bank loan, or for specific industries, such as retail.

            Proofread your completed plan (or have someone proofread it for you)
            to make sure it’s free of spelling and grammatical errors and that
            all figures are accurate.
          TEXT
        )
      end
    end
  end
end
