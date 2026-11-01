import React, { useState } from 'react';

// 가상의 편지 데이터 (Mock Data)
const INITIAL_LETTERS = [
  {
    id: 1,
    sender: "엄마",
    receiver: "나에게",
    content: "고생이 많다. 밥 잘 챙겨 먹어라. 날씨가 쌀쌀하니 감기 조심하고.",
    date: "오늘 오전 10:30",
    isAnonymous: false,
    isRead: false,
  },
  {
    id: 2,
    sender: "둘째",
    receiver: "가족 모두에게",
    content: "이번 주 주말 병원 동행은 제가 갈게요. 서류 미리 준비해주세요.",
    date: "어제 오후 04:15",
    isAnonymous: false,
    isRead: true,
  },
  {
    id: 3,
    sender: "아빠",
    receiver: "가족 모두에게",
    content: "오늘 약 드시는 시간 확인 부탁한다.",
    date: "어제 오전 09:00",
    isAnonymous: true,
    isRead: false,
  },
];

export default function FamilyMailboxApp() {
  // 편지함 모달 열림 여부
  const [isMailboxOpen, setIsMailboxOpen] = useState(false);
  
  // 탭 상태: 'inbox' | 'compose'
  const [activeTab, setActiveTab] = useState('inbox');
  
  // 편지 목록 상태
  const [letters, setLetters] = useState(INITIAL_LETTERS);
  
  // 읽기 모달용 선택된 편지
  const [selectedLetter, setSelectedLetter] = useState(null);

  // 편지 작성 폼 상태
  const [formReceiver, setFormReceiver] = useState('가족 모두에게');
  const [formIsAnonymous, setFormIsAnonymous] = useState(false);
  const [formContent, setFormContent] = useState('');

  // 편지 상세 보기 (읽기) 및 읽음 처리
  const handleOpenLetter = (letter) => {
    setSelectedLetter(letter);
    setLetters((prev) =>
      prev.map((item) =>
        item.id === letter.id ? { ...item, isRead: true } : item
      )
    );
  };

  // 편지 작성 완료 및 전송
  const handleSendLetter = (e) => {
    e.preventDefault();
    if (!formContent.trim()) return;

    const newLetter = {
      id: Date.now(),
      sender: formIsAnonymous ? "익명" : "나",
      receiver: formReceiver,
      content: formContent,
      date: "방금 전",
      isAnonymous: formIsAnonymous,
      isRead: false,
    };

    setLetters([newLetter, ...letters]);
    setFormContent('');
    setFormIsAnonymous(false);
    setFormReceiver('가족 모두에게');
    setActiveTab('inbox');
  };

  // 안 읽은 편지 수
  const unreadCount = letters.filter((l) => !l.isRead).length;

  return (
    <div className="min-h-screen bg-gray-100 font-sans flex justify-center items-center p-4">
      {/* 모바일 사이즈 레이아웃 (Max-width: md) */}
      <div className="w-full max-w-md bg-white border-2 border-black min-h-[640px] flex flex-col justify-between relative">
        
        {/* ========================================================= */}
        {/* 홈 화면 헤더 (나무와 꽃 홈화면 + 우측 상단 편지함 버튼) */}
        {/* ========================================================= */}
        <header className="border-b-2 border-black p-4 flex justify-between items-center bg-gray-50">
          <div>
            <h1 className="font-bold text-lg text-black">예소 (Yeso)</h1>
            <p className="text-xs text-gray-600">가족 공동 돌봄 정원</p>
          </div>
          
          {/* 우측 상단 편지함 버튼 */}
          <button
            onClick={() => setIsMailboxOpen(true)}
            className="border-2 border-black bg-white px-3 py-1.5 font-bold text-sm hover:bg-gray-200 flex items-center gap-1.5 relative"
          >
            <span>편지함</span>
            <span className="text-xs">✉</span>
            {unreadCount > 0 && (
              <span className="ml-1 bg-black text-white text-xs px-1.5 py-0.5 font-mono">
                {unreadCount}
              </span>
            )}
          </button>
        </header>

        {/* 홈 화면 메인 (나무와 꽃 시각화 와이어프레임) */}
        <main className="flex-1 p-6 flex flex-col justify-between bg-white">
          <div className="border-2 border-dashed border-gray-400 p-4 bg-gray-50 text-center">
            <p className="text-xs text-gray-500 font-mono mb-2">[ 홈 화면 정원 메인 ]</p>
            
            {/* 나무 와이어프레임 */}
            <div className="my-4 border border-black bg-gray-200 p-4 text-center">
              <div className="border border-black bg-white inline-block px-4 py-2 text-sm font-bold mb-1">
                🌳 돌봄 나무
              </div>
              <p className="text-xs text-gray-600">가족들의 마음이 모여 자라는 나무입니다.</p>
            </div>

            {/* 꽃 와이어프레임 */}
            <div className="grid grid-cols-3 gap-2 mt-3">
              <div className="border border-black bg-white p-2 text-xs">🌸 엄마의 꽃</div>
              <div className="border border-black bg-white p-2 text-xs">🌻 아빠의 꽃</div>
              <div className="border border-black bg-white p-2 text-xs">🌼 나의 꽃</div>
            </div>
          </div>

          <div className="mt-4 border border-black p-3 bg-gray-100 text-xs text-gray-700">
            <p className="font-bold mb-1">💡 안내</p>
            <p>우측 상단의 <strong>[편지함]</strong> 버튼을 누르면 가족 편지함이 열립니다.</p>
          </div>
        </main>

        <footer className="border-t-2 border-black p-3 text-center text-xs text-gray-500 bg-gray-50">
          예소(Yeso) - 치매 환자 가족 공동 돌봄 서비스
        </footer>


        {/* ========================================================= */}
        {/* 가족 편지함 (Family Mailbox) 모달 / 화면 */}
        {/* ========================================================= */}
        {isMailboxOpen && (
          <div className="absolute inset-0 bg-white z-10 flex flex-col">
            
            {/* 편지함 상단 헤더 */}
            <div className="border-b-2 border-black p-4 flex justify-between items-center bg-gray-100">
              <h2 className="font-bold text-base text-black">가족 편지함</h2>
              <button
                onClick={() => setIsMailboxOpen(false)}
                className="border border-black bg-white px-3 py-1 text-xs font-bold hover:bg-gray-200"
              >
                닫기 [X]
              </button>
            </div>

            {/* 1. 상단 탭 네비게이션 */}
            <div className="flex border-b-2 border-black bg-gray-50">
              <button
                onClick={() => setActiveTab('inbox')}
                className={`flex-1 py-3 text-center text-sm font-bold border-r border-black ${
                  activeTab === 'inbox'
                    ? 'border-b-4 border-b-black bg-white text-black'
                    : 'border-b border-b-gray-300 text-gray-500 hover:bg-gray-100'
                }`}
              >
                받은 편지함 ({letters.length})
              </button>
              <button
                onClick={() => setActiveTab('compose')}
                className={`flex-1 py-3 text-center text-sm font-bold ${
                  activeTab === 'compose'
                    ? 'border-b-4 border-b-black bg-white text-black'
                    : 'border-b border-b-gray-300 text-gray-500 hover:bg-gray-100'
                }`}
              >
                편지 쓰기
              </button>
            </div>

            {/* 탭 본문 영역 */}
            <div className="flex-1 p-4 overflow-y-auto bg-white">
              
              {/* =================================================== */}
              {/* 2. 받은 편지함 (Inbox Tab) */}
              {/* =================================================== */}
              {activeTab === 'inbox' && (
                <div className="space-y-3">
                  {letters.length === 0 ? (
                    <div className="border border-dashed border-gray-400 p-8 text-center text-gray-500 text-sm">
                      받은 편지가 없습니다.
                    </div>
                  ) : (
                    letters.map((letter) => (
                      <div
                        key={letter.id}
                        onClick={() => handleOpenLetter(letter)}
                        className={`border-2 border-black p-3 cursor-pointer hover:bg-gray-100 transition-colors ${
                          !letter.isRead ? 'bg-gray-100 font-semibold' : 'bg-white'
                        }`}
                      >
                        <div className="flex justify-between items-center mb-1 text-xs border-b border-gray-300 pb-1">
                          <div className="flex items-center gap-1.5">
                            {!letter.isRead && (
                              <span className="border border-black bg-black text-white px-1 py-0.2 text-[10px] font-bold">
                                [안 읽음]
                              </span>
                            )}
                            <span className="font-bold text-gray-900">
                              {letter.isAnonymous ? '[익명]' : letter.sender}
                            </span>
                            <span className="text-gray-500">➜ {letter.receiver}</span>
                          </div>
                          <span className="text-gray-500">{letter.date}</span>
                        </div>

                        <p className="text-sm text-gray-800 line-clamp-2 mt-1">
                          {letter.content}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* =================================================== */}
              {/* 3. 편지 쓰기 (Compose Tab) */}
              {/* =================================================== */}
              {activeTab === 'compose' && (
                <form onSubmit={handleSendLetter} className="space-y-4">
                  {/* 수신자 선택 (Select) */}
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">
                      수신자 선택
                    </label>
                    <select
                      value={formReceiver}
                      onChange={(e) => setFormReceiver(e.target.value)}
                      className="w-full border-2 border-black p-2 bg-white text-sm focus:outline-none"
                    >
                      <option value="가족 모두에게">가족 모두에게</option>
                      <option value="엄마">엄마</option>
                      <option value="아빠">아빠</option>
                      <option value="첫째">첫째</option>
                      <option value="둘째">둘째</option>
                      <option value="나에게">나에게</option>
                    </select>
                  </div>

                  {/* 익명 옵션 (Checkbox) */}
                  <div className="flex items-center gap-2 border border-gray-300 p-2.5 bg-gray-50">
                    <input
                      type="checkbox"
                      id="anonymous"
                      checked={formIsAnonymous}
                      onChange={(e) => setFormIsAnonymous(e.target.checked)}
                      className="w-4 h-4 border-2 border-black accent-black cursor-pointer"
                    />
                    <label htmlFor="anonymous" className="text-xs font-bold text-gray-800 cursor-pointer select-none">
                      익명으로 보내기
                    </label>
                  </div>

                  {/* 내용 작성 (Textarea) */}
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">
                      편지 내용
                    </label>
                    <textarea
                      rows={6}
                      value={formContent}
                      onChange={(e) => setFormContent(e.target.value)}
                      placeholder="가족에게 마음을 전하는 따뜻한 이야기를 적어주세요..."
                      className="w-full border-2 border-black p-3 bg-white text-sm focus:outline-none resize-none placeholder-gray-400"
                      required
                    />
                  </div>

                  {/* 전송 버튼 */}
                  <button
                    type="submit"
                    className="w-full border-2 border-black bg-gray-200 py-3 text-sm font-bold text-black hover:bg-gray-300 active:bg-gray-400"
                  >
                    편지 보내기
                  </button>
                </form>
              )}
            </div>

            {/* 편지 읽기 모달 (Modal) */}
            {selectedLetter && (
              <div className="fixed inset-0 bg-black bg-opacity-40 z-20 flex items-center justify-center p-4">
                <div className="bg-white border-2 border-black p-5 w-full max-w-sm space-y-4">
                  <div className="border-b-2 border-black pb-2 flex justify-between items-start">
                    <div>
                      <p className="text-xs text-gray-500">
                        발신: <span className="font-bold text-black">{selectedLetter.isAnonymous ? '[익명]' : selectedLetter.sender}</span>
                      </p>
                      <p className="text-xs text-gray-500">
                        수신: <span className="font-bold text-black">{selectedLetter.receiver}</span>
                      </p>
                    </div>
                    <span className="text-xs text-gray-500">{selectedLetter.date}</span>
                  </div>

                  <div className="py-2 text-sm text-gray-900 whitespace-pre-wrap min-h-[100px] border border-gray-200 p-3 bg-gray-50">
                    {selectedLetter.content}
                  </div>

                  <div className="flex justify-end">
                    <button
                      onClick={() => setSelectedLetter(null)}
                      className="border-2 border-black bg-gray-100 hover:bg-gray-200 px-4 py-1.5 text-xs font-bold"
                    >
                      닫기
                    </button>
                  </div>
                </div>
              </div>
            )}

          </div>
        )}

      </div>
    </div>
  );
}
